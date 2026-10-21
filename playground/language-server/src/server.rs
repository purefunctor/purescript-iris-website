//! The protocol: lifecycle, document notifications, requests, and deferred diagnostics.
//!
//! [`Server::handle`] answers one message at once. Diagnostics are not collected there: changes
//! queue the affected project sources, and the host drains the queue with
//! [`Server::next_diagnostics`] while no messages are waiting. Several quick edits therefore
//! collect diagnostics once, and requests never wait behind a diagnostic pass.

use std::collections::VecDeque;
use std::sync::Arc;

use building::lifecycle::{
    AnalysisInvalidation, DiskObservation, DocumentKey, DocumentKind, ForeignEvent,
    LifecycleChange, LifecycleEvent, SourceEvent, SourceUnitKey,
};
use files::{FileId, ForeignSourceKind};
use iris_analysis::position::{PositionConverter, PositionEncoding};
use lsp_types::*;
use serde::Deserialize;
use serde_json::{Value, json};

use crate::capabilities::{
    initialize_result, negotiate_analyzer_capabilities, negotiate_position_encoding,
};
use crate::protocol::{Rejection, notification, response};
use crate::workspace::{
    PROJECT_ROOT, Package, PackageFile, SourceMetadata, Workspace, document_unit,
};
use crate::{emit, requests};

#[derive(Default)]
pub struct Server {
    workspace: Workspace,
    initialized: bool,
    pending_diagnostics: VecDeque<FileId>,
}

#[derive(Deserialize)]
struct InitializeParams {
    capabilities: ClientCapabilities,
}

/// The parameters of `textDocument/didChange`. As in the native server, a change replaces the
/// whole document only when `range` is absent, so a malformed range is rejected.
#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct DidChangeParameters {
    text_document: VersionedTextDocumentIdentifier,
    content_changes: Vec<ContentChange>,
}

#[derive(Deserialize)]
struct ContentChange {
    range: Option<Range>,
    text: String,
}

/// The parameters of `iris/setPackages`, which replaces every package source.
#[derive(Deserialize)]
struct SetPackagesParams {
    packages: Vec<PackageParams>,
}

#[derive(Deserialize)]
struct PackageParams {
    name: String,
    files: Vec<PackageFileParams>,
}

#[derive(Deserialize)]
struct PackageFileParams {
    path: String,
    text: String,
}

impl Server {
    /// Handles one JSON-RPC message and returns the messages to send back.
    pub fn handle(&mut self, message: Value) -> Vec<Value> {
        let method = message.get("method").and_then(Value::as_str).map(str::to_string);
        let id = message.get("id").cloned();
        let params = message.get("params").cloned().unwrap_or(Value::Null);
        match (id, method) {
            (Some(id), Some(method)) => {
                let mut outgoing = Vec::new();
                let result = self.request(&method, params, &mut outgoing);
                outgoing.insert(0, response(id, result));
                outgoing
            }
            (None, Some(method)) => self.notification(&method, params),
            // Responses from the client; the server sends no requests.
            (_, None) => Vec::new(),
        }
    }

    /// Collects diagnostics for the next queued project source, or returns `None` when the queue
    /// is empty.
    pub fn next_diagnostics(&mut self) -> Option<Value> {
        loop {
            let file_id = self.pending_diagnostics.pop_front()?;
            if !self.workspace.files.contains_source(file_id) {
                continue;
            }
            let version = self.workspace.files.source_version(file_id);
            let collected = self.workspace.analyzer().with_context(|context| {
                iris_analysis::diagnostics::implementation(context, file_id)
            });
            let Ok(collected) = collected else {
                continue;
            };
            let params = PublishDiagnosticsParams {
                uri: collected.uri,
                diagnostics: collected.diagnostics,
                version,
            };
            return Some(notification(
                "textDocument/publishDiagnostics",
                serde_json::to_value(params).expect("invariant violated: params must serialize"),
            ));
        }
    }

    /// The text of a project or package file, including package foreign files.
    pub fn read_source(&self, uri: &str) -> Option<String> {
        if let Some(file_id) = self.workspace.files.source_id(uri)
            && let Ok(content) = self.workspace.engine.content(file_id)
        {
            return Some(content.to_string());
        }
        self.workspace.package_text(uri).map(|text| text.to_string())
    }

    fn request(
        &mut self,
        method: &str,
        params: Value,
        outgoing: &mut Vec<Value>,
    ) -> Result<Value, Rejection> {
        if method == "initialize" {
            let params: InitializeParams = decode(params)?;
            self.workspace.position_encoding = negotiate_position_encoding(&params.capabilities);
            self.workspace.capabilities = negotiate_analyzer_capabilities(&params.capabilities);
            self.initialized = true;
            let result = initialize_result(self.workspace.position_encoding);
            return Ok(serde_json::to_value(result).expect("invariant violated: must serialize"));
        }
        if !self.initialized {
            return Err(Rejection::ServerNotInitialized);
        }
        match method {
            "shutdown" => Ok(Value::Null),
            "iris/setPackages" => {
                let params: SetPackagesParams = decode(params)?;
                let packages = params.packages.into_iter().map(|package| Package {
                    name: package.name,
                    files: package
                        .files
                        .into_iter()
                        .map(|file| PackageFile { path: file.path, text: file.text })
                        .collect(),
                });
                let change = self.workspace.set_packages(packages.collect());
                self.schedule(&change, None, outgoing);
                Ok(json!({ "sources": self.workspace.package_sources() }))
            }
            "iris/emit" => {
                let emitted = emit::emit(&self.workspace)
                    .map_err(|error| Rejection::RequestFailed(error.to_string()))?;
                Ok(serde_json::to_value(emitted).expect("invariant violated: must serialize"))
            }
            method => requests::handle(&mut self.workspace, method, params),
        }
    }

    fn notification(&mut self, method: &str, params: Value) -> Vec<Value> {
        if !self.initialized {
            return Vec::new();
        }
        let mut outgoing = Vec::new();
        let result = match method {
            "textDocument/didOpen" => {
                decode(params).and_then(|params| self.did_open(params, &mut outgoing))
            }
            "textDocument/didChange" => {
                decode(params).and_then(|params| self.did_change(params, &mut outgoing))
            }
            "textDocument/didClose" => {
                decode(params).and_then(|params| self.did_close(params, &mut outgoing))
            }
            _ => Ok(()),
        };
        if let Err(rejection) = result {
            let message = rejection.message();
            outgoing
                .push(notification("window/logMessage", json!({ "type": 1, "message": message })));
        }
        outgoing
    }

    fn did_open(
        &mut self,
        params: DidOpenTextDocumentParams,
        outgoing: &mut Vec<Value>,
    ) -> Result<(), Rejection> {
        let document = params.text_document;
        let (kind, unit) = project_document(&document.uri)?;
        let text = Arc::from(document.text);
        let version = document.version;
        let mut events = Vec::new();
        match kind {
            DocumentKind::Source => {
                events.push(LifecycleEvent::Source {
                    unit: SourceUnitKey::clone(&unit),
                    event: SourceEvent::Opened { text, version, metadata: SourceMetadata::Project },
                });
                events.extend(self.missing_foreign_siblings(&unit));
            }
            DocumentKind::Foreign(kind) => {
                events.push(LifecycleEvent::Foreign {
                    unit: SourceUnitKey::clone(&unit),
                    kind,
                    event: ForeignEvent::Opened { text, version },
                });
            }
        }
        let change = self.workspace.apply(events);
        self.schedule(&change, Some(&unit), outgoing);
        Ok(())
    }

    fn did_change(
        &mut self,
        params: DidChangeParameters,
        outgoing: &mut Vec<Value>,
    ) -> Result<(), Rejection> {
        if params.content_changes.is_empty() {
            return Ok(());
        }
        let uri = &params.text_document.text_document_identifier.uri;
        let version = params.text_document.version;
        let (kind, unit) = project_document(uri)?;
        let content = self.document_content(kind, uri)?;
        let text = apply_content_changes(
            &content,
            &params.content_changes,
            self.workspace.position_encoding,
        )
        .ok_or_else(|| Rejection::InvalidParams(format!("Invalid content change for {uri:?}")))?;
        let event = match kind {
            DocumentKind::Source => LifecycleEvent::Source {
                unit: SourceUnitKey::clone(&unit),
                event: SourceEvent::Changed { text, version },
            },
            DocumentKind::Foreign(kind) => LifecycleEvent::Foreign {
                unit: SourceUnitKey::clone(&unit),
                kind,
                event: ForeignEvent::Changed { text, version },
            },
        };
        let change = self.workspace.apply([event]);
        self.schedule(&change, Some(&unit), outgoing);
        Ok(())
    }

    /// Closing a project document removes it: the playground has no disk to fall back to.
    fn did_close(
        &mut self,
        params: DidCloseTextDocumentParams,
        outgoing: &mut Vec<Value>,
    ) -> Result<(), Rejection> {
        let (kind, unit) = project_document(&params.text_document.uri)?;
        let disk = DiskObservation::NotFound;
        let event = match kind {
            DocumentKind::Source => LifecycleEvent::Source {
                unit: SourceUnitKey::clone(&unit),
                event: SourceEvent::Closed { disk },
            },
            DocumentKind::Foreign(kind) => LifecycleEvent::Foreign {
                unit: SourceUnitKey::clone(&unit),
                kind,
                event: ForeignEvent::Closed { disk },
            },
        };
        let change = self.workspace.apply([event]);
        self.schedule(&change, Some(&unit), outgoing);
        Ok(())
    }

    /// Foreign siblings of a newly opened source that the editor has not opened. They are
    /// observed as missing, as the native server observes them on disk.
    fn missing_foreign_siblings(
        &self,
        unit: &SourceUnitKey,
    ) -> Vec<LifecycleEvent<i32, SourceMetadata>> {
        let mut events = Vec::new();
        for kind in ForeignSourceKind::ALL {
            let document = DocumentKey::Foreign(SourceUnitKey::clone(unit), kind);
            if !self.workspace.files.is_open(&document) {
                events.push(LifecycleEvent::Foreign {
                    unit: SourceUnitKey::clone(unit),
                    kind,
                    event: ForeignEvent::DiskObserved { disk: DiskObservation::NotFound },
                });
            }
        }
        events
    }

    fn document_content(&self, kind: DocumentKind, uri: &Uri) -> Result<Arc<str>, Rejection> {
        let unknown = || Rejection::InvalidParams(format!("Unknown document {uri:?}"));
        let files = &self.workspace.files;
        let engine = &self.workspace.engine;
        match kind {
            DocumentKind::Source => {
                let file_id = files.source_id(uri.as_str()).ok_or_else(unknown)?;
                engine.content(file_id).map_err(|_| unknown())
            }
            DocumentKind::Foreign(_) => {
                let file_id = files.foreign_id(uri.as_str()).ok_or_else(unknown)?;
                engine.foreign_content(file_id).ok_or_else(unknown)
            }
        }
    }

    /// Clears the diagnostics of removed project sources and queues collection for the project
    /// sources a change affects, including the one the edited document belongs to.
    fn schedule(
        &mut self,
        change: &LifecycleChange,
        unit: Option<&SourceUnitKey>,
        outgoing: &mut Vec<Value>,
    ) {
        for removed in change.removed_sources() {
            if removed.locator.starts_with(PROJECT_ROOT) {
                self.pending_diagnostics.retain(|file_id| *file_id != removed.file_id);
                outgoing.push(notification(
                    "textDocument/publishDiagnostics",
                    json!({ "uri": &*removed.locator, "diagnostics": [] }),
                ));
            }
        }
        let mut affected = Vec::new();
        if let Some(file_id) = unit.and_then(|unit| self.workspace.files.source_id(unit.source())) {
            affected.push(file_id);
        }
        match change.analysis() {
            AnalysisInvalidation::None => {}
            AnalysisInvalidation::Sources(sources) => affected.extend(sources.iter().copied()),
            AnalysisInvalidation::Workspace => affected.extend(self.workspace.project_sources()),
        }
        for file_id in affected {
            let project =
                self.workspace.files.source_metadata(file_id) == Some(&SourceMetadata::Project);
            if project && !self.pending_diagnostics.contains(&file_id) {
                self.pending_diagnostics.push_back(file_id);
            }
        }
    }
}

impl Rejection {
    fn message(self) -> String {
        match self {
            Rejection::InvalidParams(message)
            | Rejection::RequestFailed(message)
            | Rejection::MethodNotFound(message) => message,
            Rejection::ServerNotInitialized => "Server is not initialized".to_string(),
            Rejection::ContentModified => "Content modified".to_string(),
        }
    }
}

fn decode<T: for<'de> Deserialize<'de>>(params: Value) -> Result<T, Rejection> {
    serde_json::from_value(params).map_err(|error| {
        Rejection::InvalidParams(format!("Failed to deserialize parameters: {error}"))
    })
}

fn project_document(uri: &Uri) -> Result<(DocumentKind, SourceUnitKey), Rejection> {
    if !uri.as_str().starts_with(PROJECT_ROOT) {
        return Err(Rejection::InvalidParams(format!("{uri:?} is not a project document")));
    }
    document_unit(uri.as_str())
        .ok_or_else(|| Rejection::InvalidParams(format!("{uri:?} is not a source or FFI file")))
}

/// Applies incremental changes, as `apply_content_changes` in the native server does.
fn apply_content_changes(
    content: &str,
    content_changes: &[ContentChange],
    position_encoding: PositionEncoding,
) -> Option<Arc<str>> {
    let mut content = content.to_string();
    for content_change in content_changes {
        let Some(range) = content_change.range else {
            content = String::clone(&content_change.text);
            continue;
        };
        let positions = PositionConverter::new(&content, position_encoding);
        let offset = |position| {
            positions
                .protocol_position_to_utf8(position)
                .and_then(|position| positions.utf8_position_to_offset(position))
        };
        let start = usize::from(offset(range.start)?);
        let end = usize::from(offset(range.end)?);
        if start > end {
            return None;
        }
        content.replace_range(start..end, &content_change.text);
    }
    Some(Arc::from(content))
}
