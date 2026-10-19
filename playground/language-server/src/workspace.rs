//! The query engine, the documents and package sources it reads, and the analyzer host over them.
//!
//! Everything runs on one thread. Analysis borrows the engine directly instead of taking a
//! snapshot, because an input change waits for every snapshot to be dropped, and on a single
//! thread that wait can never finish.
//!
//! The playground receives the whole package set, but the engine only loads the package sources
//! that the project imports, directly or through other packages. Loading a source parses it to
//! register its module name and keeps the syntax tree, which for all 10,000 sources of the package
//! set takes about 900 MiB of memory and four seconds. Unloaded sources stay as text, indexed by
//! the module name in their header.

use std::collections::{HashMap, HashSet};
use std::sync::Arc;

use building::QueryEngine;
use building::lifecycle::{
    AnalysisInvalidation, DiskObservation, DocumentKind, FileLifecycle, ForeignEvent,
    LifecycleChange, LifecycleEvent, SourceEvent, SourceUnitKey,
};
use files::{FileId, ForeignSourceKind};
use iris_analysis::completion::SuggestionsCache;
use iris_analysis::position::PositionEncoding;
use iris_analysis::symbols::WorkspaceSymbolsCache;
use iris_analysis::{AnalyzerCapabilities, AnalyzerContext, AnalyzerHost};
use lsp_types::Uri;
use prim_constants::MODULE_MAP;
use syntax::ast::AstNode;

/// Where the playground's documents live. Project files are opened by the editor; package and Prim
/// sources are read-only.
pub const PROJECT_ROOT: &str = "file:///project/";
pub const PACKAGES_ROOT: &str = "file:///packages/";
pub const PRIM_ROOT: &str = "file:///prim/";

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum SourceMetadata {
    Prim,
    Package,
    Project,
}

/// A package source file, relative to the package root, such as `src/Data/Maybe.purs`.
pub struct PackageFile {
    pub path: String,
    pub text: String,
}

pub struct Package {
    pub name: String,
    pub files: Vec<PackageFile>,
}

pub struct Workspace {
    pub engine: QueryEngine,
    pub files: FileLifecycle<i32, SourceMetadata>,
    pub suggestions: SuggestionsCache,
    pub workspace_symbols: WorkspaceSymbolsCache,
    pub position_encoding: PositionEncoding,
    pub capabilities: AnalyzerCapabilities,
    packages: PackageSources,
    /// Package units in the engine, with the foreign kinds loaded for each.
    loaded: HashMap<SourceUnitKey, Vec<ForeignSourceKind>>,
    /// Loaded package sources whose imports have been followed. Package sources never change
    /// while loaded, so each is read once.
    followed: HashSet<FileId>,
}

/// Every package file, loaded or not.
#[derive(Default)]
struct PackageSources {
    /// File contents by locator.
    texts: HashMap<String, Arc<str>>,
    /// Source units by the module name their header declares.
    modules: HashMap<String, Vec<SourceUnitKey>>,
    /// Source units whose header could not be read, which are loaded unconditionally so that the
    /// parser decides their module name.
    unnamed: Vec<SourceUnitKey>,
    foreign: HashMap<SourceUnitKey, Vec<ForeignSourceKind>>,
}

impl Default for Workspace {
    fn default() -> Workspace {
        let engine = QueryEngine::default();
        let mut files = FileLifecycle::default();
        for (name, content) in MODULE_MAP {
            let unit = source_unit(&format!("{PRIM_ROOT}{name}.purs"));
            let event = LifecycleEvent::Source {
                unit,
                event: SourceEvent::DiskObserved {
                    disk: DiskObservation::Found(Arc::from(*content)),
                    metadata: SourceMetadata::Prim,
                },
            };
            let change = files.apply(&engine, event);
            let id = change
                .changed_sources()
                .next()
                .expect("invariant violated: Prim source lifecycle did not insert a source");
            engine.insert_module_file(name, id);
        }
        Workspace {
            engine,
            files,
            suggestions: SuggestionsCache::default(),
            workspace_symbols: WorkspaceSymbolsCache::default(),
            position_encoding: PositionEncoding::Utf16,
            capabilities: AnalyzerCapabilities::default(),
            packages: PackageSources::default(),
            loaded: HashMap::new(),
            followed: HashSet::new(),
        }
    }
}

impl Workspace {
    pub fn analyzer(&self) -> Analyzer<'_> {
        Analyzer {
            engine: &self.engine,
            files: &self.files,
            position_encoding: self.position_encoding,
            capabilities: self.capabilities,
        }
    }

    /// The analyzer together with the caches that some requests update while they read it.
    pub fn analyzer_with_caches(
        &mut self,
    ) -> (Analyzer<'_>, &mut SuggestionsCache, &mut WorkspaceSymbolsCache) {
        let analyzer = Analyzer {
            engine: &self.engine,
            files: &self.files,
            position_encoding: self.position_encoding,
            capabilities: self.capabilities,
        };
        (analyzer, &mut self.suggestions, &mut self.workspace_symbols)
    }

    /// Applies document events, then loads the package sources that the project now imports.
    pub fn apply(
        &mut self,
        events: impl IntoIterator<Item = LifecycleEvent<i32, SourceMetadata>>,
    ) -> LifecycleChange {
        let mut change = self.files.apply_all(&self.engine, events);
        change.combine(self.load_imported_packages());
        if !matches!(change.analysis(), AnalysisInvalidation::None) {
            self.suggestions = SuggestionsCache::default();
            self.workspace_symbols = WorkspaceSymbolsCache::default();
        }
        change
    }

    /// Replaces every package source. Loaded sources that are unchanged keep their analysis, and
    /// the rest load once an import reaches them.
    pub fn set_packages(&mut self, packages: Vec<Package>) -> LifecycleChange {
        let mut next = PackageSources::default();
        let mut foreign_units = Vec::new();
        for package in packages {
            for file in package.files {
                let locator = format!("{PACKAGES_ROOT}{}/{}", package.name, file.path);
                let Some(kind) = document_kind(&locator) else {
                    continue;
                };
                match kind {
                    DocumentKind::Source => {
                        let unit = source_unit(&locator);
                        match module_header_name(&file.text) {
                            Some(name) => {
                                next.modules.entry(name.to_string()).or_default().push(unit)
                            }
                            None => next.unnamed.push(unit),
                        }
                    }
                    DocumentKind::Foreign(kind) => {
                        foreign_units.push((source_unit(&sibling(&locator, "purs")), kind));
                    }
                }
                next.texts.insert(locator, Arc::from(file.text));
            }
        }
        for (unit, kind) in foreign_units {
            if next.texts.contains_key(unit.source()) {
                next.foreign.entry(unit).or_default().push(kind);
            }
        }

        // Reload the loaded units that remain, so that changed ones are reanalyzed, and remove the
        // rest.
        let mut events = Vec::new();
        let loaded = std::mem::take(&mut self.loaded);
        for (unit, kinds) in &loaded {
            let current = next.foreign.get(unit).map_or(&[][..], Vec::as_slice);
            for kind in kinds {
                if !current.contains(kind) {
                    events.push(LifecycleEvent::Foreign {
                        unit: SourceUnitKey::clone(unit),
                        kind: *kind,
                        event: ForeignEvent::DiskObserved { disk: DiskObservation::NotFound },
                    });
                }
            }
            if !next.texts.contains_key(unit.source()) {
                events.push(LifecycleEvent::Source {
                    unit: SourceUnitKey::clone(unit),
                    event: SourceEvent::DiskObserved {
                        disk: DiskObservation::NotFound,
                        metadata: SourceMetadata::Package,
                    },
                });
            }
        }
        self.packages = next;
        for unit in loaded.into_keys() {
            if self.packages.texts.contains_key(unit.source()) {
                events.extend(self.load_events(&unit));
            }
        }
        self.followed.clear();
        self.apply(events)
    }

    /// The text of a package file, whether or not it is loaded.
    pub fn package_text(&self, locator: &str) -> Option<Arc<str>> {
        self.packages.texts.get(locator).cloned()
    }

    /// The number of package sources available and loaded.
    pub fn package_counts(&self) -> (usize, usize) {
        let available = self.packages.modules.values().map(Vec::len).sum::<usize>()
            + self.packages.unnamed.len();
        (available, self.loaded.len())
    }

    /// Loads the package sources that loaded sources import, until every import that the
    /// packages provide is loaded.
    fn load_imported_packages(&mut self) -> LifecycleChange {
        let mut change = LifecycleChange::default();
        self.followed.retain(|file_id| self.files.contains_source(*file_id));
        let mut wanted: Vec<SourceUnitKey> = self
            .packages
            .unnamed
            .iter()
            .filter(|unit| !self.loaded.contains_key(*unit))
            .cloned()
            .collect();
        loop {
            let sources: Vec<FileId> = self.files.source_ids().collect();
            for file_id in sources {
                match self.files.source_metadata(file_id) {
                    Some(SourceMetadata::Prim) | None => continue,
                    Some(SourceMetadata::Package) => {
                        if !self.followed.insert(file_id) {
                            continue;
                        }
                    }
                    Some(SourceMetadata::Project) => {}
                }
                for name in self.imports(file_id) {
                    let Some(units) = self.packages.modules.get(&name) else {
                        continue;
                    };
                    for unit in units {
                        if !self.loaded.contains_key(unit) && !wanted.contains(unit) {
                            wanted.push(SourceUnitKey::clone(unit));
                        }
                    }
                }
            }
            if wanted.is_empty() {
                return change;
            }
            let mut events = Vec::new();
            for unit in std::mem::take(&mut wanted) {
                events.extend(self.load_events(&unit));
            }
            change.combine(self.files.apply_all(&self.engine, events));
        }
    }

    /// The events that load a package unit, which also record it as loaded.
    fn load_events(&mut self, unit: &SourceUnitKey) -> Vec<LifecycleEvent<i32, SourceMetadata>> {
        let mut events = Vec::new();
        let Some(text) = self.packages.texts.get(unit.source()) else {
            return events;
        };
        events.push(LifecycleEvent::Source {
            unit: SourceUnitKey::clone(unit),
            event: SourceEvent::DiskObserved {
                disk: DiskObservation::Found(Arc::clone(text)),
                metadata: SourceMetadata::Package,
            },
        });
        let kinds = self.packages.foreign.get(unit).cloned().unwrap_or_default();
        for kind in &kinds {
            let extension = match kind {
                ForeignSourceKind::JavaScript => "js",
                ForeignSourceKind::Jsx => "jsx",
            };
            let Some(text) = self.packages.texts.get(&sibling(unit.source(), extension)) else {
                continue;
            };
            events.push(LifecycleEvent::Foreign {
                unit: SourceUnitKey::clone(unit),
                kind: *kind,
                event: ForeignEvent::DiskObserved {
                    disk: DiskObservation::Found(Arc::clone(text)),
                },
            });
        }
        self.loaded.insert(SourceUnitKey::clone(unit), kinds);
        events
    }

    /// The module names that a loaded source imports.
    fn imports(&self, file_id: FileId) -> Vec<String> {
        let (Ok(content), Ok((parsed, _))) =
            (self.engine.content(file_id), self.engine.parsed(file_id))
        else {
            return Vec::new();
        };
        let Some(imports) = parsed.cst().imports() else {
            return Vec::new();
        };
        imports
            .children()
            .filter_map(|import| import.module_name())
            .map(|name| name.syntax().text(&content).trim().to_string())
            .collect()
    }

    /// Project sources, which are the only ones that receive diagnostics.
    pub fn project_sources(&self) -> impl Iterator<Item = FileId> + '_ {
        self.files.source_ids().filter(|file_id| {
            self.files.source_metadata(*file_id) == Some(&SourceMetadata::Project)
        })
    }
}

pub struct Analyzer<'a> {
    pub engine: &'a QueryEngine,
    files: &'a FileLifecycle<i32, SourceMetadata>,
    position_encoding: PositionEncoding,
    capabilities: AnalyzerCapabilities,
}

impl Analyzer<'_> {
    pub fn with_context<T>(
        &self,
        action: impl FnOnce(&AnalyzerContext<PlaygroundHost<'_>>) -> T,
    ) -> T {
        let host = PlaygroundHost { engine: self.engine, files: self.files };
        let context = AnalyzerContext::new(&host, self.position_encoding, self.capabilities);
        action(&context)
    }
}

pub struct PlaygroundHost<'a> {
    engine: &'a QueryEngine,
    files: &'a FileLifecycle<i32, SourceMetadata>,
}

impl AnalyzerHost for PlaygroundHost<'_> {
    type Queries = QueryEngine;

    fn queries(&self) -> &QueryEngine {
        self.engine
    }

    fn file_id(&self, uri: &str) -> Option<FileId> {
        self.files.source_id(uri)
    }

    fn file_uri(&self, file_id: FileId) -> Result<Option<Uri>, url::ParseError> {
        let Some(uri) = self.files.source_path(file_id) else {
            return Ok(None);
        };
        Uri::parse(&uri).map(Some)
    }

    fn source_files(&self) -> impl Iterator<Item = FileId> {
        self.files.source_ids()
    }

    fn is_editable(&self, file_id: FileId) -> bool {
        self.files.source_metadata(file_id) == Some(&SourceMetadata::Project)
    }
}

pub fn document_kind(locator: &str) -> Option<DocumentKind> {
    if locator.ends_with(".purs") {
        Some(DocumentKind::Source)
    } else if locator.ends_with(".js") {
        Some(DocumentKind::Foreign(ForeignSourceKind::JavaScript))
    } else if locator.ends_with(".jsx") {
        Some(DocumentKind::Foreign(ForeignSourceKind::Jsx))
    } else {
        None
    }
}

/// The source unit a `.purs` locator belongs to, with its foreign siblings.
pub fn source_unit(source: &str) -> SourceUnitKey {
    SourceUnitKey::with_foreign_sources(source, sibling(source, "js"), sibling(source, "jsx"))
}

/// The source unit of any document locator, `.purs` or foreign.
pub fn document_unit(locator: &str) -> Option<(DocumentKind, SourceUnitKey)> {
    let kind = document_kind(locator)?;
    let unit = match kind {
        DocumentKind::Source => source_unit(locator),
        DocumentKind::Foreign(_) => source_unit(&sibling(locator, "purs")),
    };
    Some((kind, unit))
}

/// The module name a source's header declares, read without parsing the module. Returns `None`
/// for anything unusual, which the parser then handles.
fn module_header_name(text: &str) -> Option<&str> {
    let rest = skip_trivia(text.strip_prefix('\u{feff}').unwrap_or(text))?;
    let rest = rest.strip_prefix("module")?;
    let after = skip_trivia(rest)?;
    if after.len() == rest.len() {
        return None;
    }
    let end = after
        .find(|character: char| {
            !(character.is_alphanumeric() || matches!(character, '_' | '\'' | '.'))
        })
        .unwrap_or(after.len());
    let name = &after[..end];
    let valid =
        name.split('.').all(|segment| segment.chars().next().is_some_and(char::is_uppercase));
    valid.then_some(name)
}

/// Skips whitespace and comments, or returns `None` for an unterminated block comment.
fn skip_trivia(mut text: &str) -> Option<&str> {
    loop {
        let trimmed = text.trim_start();
        if let Some(rest) = trimmed.strip_prefix("--") {
            text = rest.find('\n').map_or("", |index| &rest[index..]);
        } else if trimmed.starts_with("{-") {
            let mut depth = 0usize;
            let mut index = 0;
            let bytes = trimmed.as_bytes();
            loop {
                if index + 1 >= bytes.len() {
                    return None;
                }
                match &bytes[index..index + 2] {
                    b"{-" => {
                        depth += 1;
                        index += 2;
                    }
                    b"-}" => {
                        depth -= 1;
                        index += 2;
                        if depth == 0 {
                            break;
                        }
                    }
                    _ => index += 1,
                }
            }
            text = &trimmed[index..];
        } else {
            return Some(trimmed);
        }
    }
}

fn sibling(locator: &str, extension: &str) -> String {
    let name_start = locator.rfind('/').map_or(0, |index| index + 1);
    let stem_end = locator[name_start..]
        .rfind('.')
        .filter(|index| *index > 0)
        .map_or(locator.len(), |index| name_start + index);
    format!("{}.{extension}", &locator[..stem_end])
}
