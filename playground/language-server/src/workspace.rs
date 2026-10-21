//! The query engine, the documents and package sources it reads, and the analyzer host over them.
//!
//! Everything runs on one thread. Analysis borrows the engine directly instead of taking a
//! snapshot, because an input change waits for every snapshot to be dropped, and on a single
//! thread that wait can never finish.
//!
//! The engine loads every package source it receives, because completion offers imports only from
//! loaded modules.

use std::collections::HashMap;
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
}

/// Every package file, all of which are loaded in the engine.
#[derive(Default)]
struct PackageSources {
    /// File contents by locator.
    texts: HashMap<String, Arc<str>>,
    /// Source units, with the foreign kinds of each.
    units: HashMap<SourceUnitKey, Vec<ForeignSourceKind>>,
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

    pub fn apply(
        &mut self,
        events: impl IntoIterator<Item = LifecycleEvent<i32, SourceMetadata>>,
    ) -> LifecycleChange {
        let change = self.files.apply_all(&self.engine, events);
        if !matches!(change.analysis(), AnalysisInvalidation::None) {
            self.suggestions = SuggestionsCache::default();
            self.workspace_symbols = WorkspaceSymbolsCache::default();
        }
        change
    }

    /// Replaces every package source. Sources that are unchanged keep their analysis.
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
                        next.units.insert(source_unit(&locator), Vec::new());
                    }
                    DocumentKind::Foreign(kind) => {
                        foreign_units.push((source_unit(&sibling(&locator, "purs")), kind));
                    }
                }
                next.texts.insert(locator, Arc::from(file.text));
            }
        }
        for (unit, kind) in foreign_units {
            if let Some(kinds) = next.units.get_mut(&unit) {
                kinds.push(kind);
            }
        }

        // Remove the sources that went away, then load every source.
        let mut events = Vec::new();
        for (unit, kinds) in &self.packages.units {
            let current = next.units.get(unit);
            for kind in kinds {
                if !current.is_some_and(|current| current.contains(kind)) {
                    events.push(LifecycleEvent::Foreign {
                        unit: SourceUnitKey::clone(unit),
                        kind: *kind,
                        event: ForeignEvent::DiskObserved { disk: DiskObservation::NotFound },
                    });
                }
            }
            if current.is_none() {
                events.push(LifecycleEvent::Source {
                    unit: SourceUnitKey::clone(unit),
                    event: SourceEvent::DiskObserved {
                        disk: DiskObservation::NotFound,
                        metadata: SourceMetadata::Package,
                    },
                });
            }
        }
        for (unit, kinds) in &next.units {
            events.extend(load_events(&next.texts, unit, kinds));
        }
        self.packages = next;
        self.apply(events)
    }

    /// The text of a package file, including foreign files.
    pub fn package_text(&self, locator: &str) -> Option<Arc<str>> {
        self.packages.texts.get(locator).cloned()
    }

    /// The number of package sources.
    pub fn package_sources(&self) -> usize {
        self.packages.units.len()
    }

    /// Project sources, which are the only ones that receive diagnostics.
    pub fn project_sources(&self) -> impl Iterator<Item = FileId> + '_ {
        self.files.source_ids().filter(|file_id| {
            self.files.source_metadata(*file_id) == Some(&SourceMetadata::Project)
        })
    }
}

/// The events that load a package unit and its foreign sources.
fn load_events(
    texts: &HashMap<String, Arc<str>>,
    unit: &SourceUnitKey,
    kinds: &[ForeignSourceKind],
) -> Vec<LifecycleEvent<i32, SourceMetadata>> {
    let mut events = Vec::new();
    let Some(text) = texts.get(unit.source()) else {
        return events;
    };
    events.push(LifecycleEvent::Source {
        unit: SourceUnitKey::clone(unit),
        event: SourceEvent::DiskObserved {
            disk: DiskObservation::Found(Arc::clone(text)),
            metadata: SourceMetadata::Package,
        },
    });
    for kind in kinds {
        let extension = match kind {
            ForeignSourceKind::JavaScript => "js",
            ForeignSourceKind::Jsx => "jsx",
        };
        let Some(text) = texts.get(&sibling(unit.source(), extension)) else {
            continue;
        };
        events.push(LifecycleEvent::Foreign {
            unit: SourceUnitKey::clone(unit),
            kind: *kind,
            event: ForeignEvent::DiskObserved { disk: DiskObservation::Found(Arc::clone(text)) },
        });
    }
    events
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

fn sibling(locator: &str, extension: &str) -> String {
    let name_start = locator.rfind('/').map_or(0, |index| index + 1);
    let stem_end = locator[name_start..]
        .rfind('.')
        .filter(|index| *index > 0)
        .map_or(locator.len(), |index| name_start + index);
    format!("{}.{extension}", &locator[..stem_end])
}
