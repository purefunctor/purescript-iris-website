//! `iris/emit`: the JavaScript for the project and every module it reaches, for the Run button.
//!
//! This follows `collect_modules` and the output layout in the Iris repository's
//! `compiler-executable/iris-build`, so generated imports such as `../Data.Maybe/index.js` and
//! `./foreign.js` resolve between the returned paths. Like `iris build`, nothing is emitted while
//! a project source has errors.

use std::collections::HashSet;

use building::QueryError;
use files::FileId;
use lsp_types::{Diagnostic, DiagnosticSeverity};
use serde::Serialize;
use serde_json::Value;

use crate::protocol::Rejection;
use crate::workspace::Workspace;

#[derive(Serialize)]
#[serde(tag = "status", rename_all = "camelCase")]
pub enum Generated {
    Failed { errors: Vec<ProjectError> },
    Generated { path: String, text: String, map: Value },
}

#[derive(Serialize)]
#[serde(tag = "status", rename_all = "camelCase")]
pub enum Emitted {
    Failed { errors: Vec<ProjectError> },
    Emitted { modules: Vec<EmittedModule>, files: Vec<EmittedFile> },
}

#[derive(Serialize)]
pub struct ProjectError {
    uri: String,
    diagnostic: Diagnostic,
}

/// A project module and the path of its generated entry, such as `Main/index.js`.
#[derive(Serialize)]
pub struct EmittedModule {
    name: String,
    uri: String,
    path: String,
}

#[derive(Serialize)]
pub struct EmittedFile {
    path: String,
    text: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    map: Option<Value>,
}

/// Generates only the requested source, even when an unrelated project source has errors.
pub fn generated(workspace: &Workspace, uri: &str) -> Result<Generated, Rejection> {
    let file_id = workspace
        .files
        .source_id(uri)
        .ok_or_else(|| Rejection::InvalidParams(format!("Unknown source document {uri:?}")))?;
    let failed = |error: QueryError| Rejection::RequestFailed(error.to_string());
    let errors = source_errors(workspace, &[file_id]).map_err(failed)?;
    if !errors.is_empty() {
        return Ok(Generated::Failed { errors });
    }
    let module = workspace
        .engine
        .javascript(file_id)
        .map_err(failed)?
        .map_err(|error| Rejection::RequestFailed(error.to_string()))?;
    let map = source_map(workspace, file_id).map_err(failed)?;
    Ok(Generated::Generated {
        path: module.filename(),
        text: module.files().index_source().to_string(),
        map,
    })
}

/// Preserve the compiler's v3 mappings (UTF-16 points, not inferred source ranges).
fn source_map(workspace: &Workspace, file_id: FileId) -> Result<Value, QueryError> {
    let map = workspace
        .engine
        .source_map(file_id)?
        .expect("invariant violated: a generated module has no source map");
    let uri = workspace
        .files
        .source_path(file_id)
        .expect("invariant violated: a generated module has no source URI");
    Ok(serde_json::from_str(&map.to_json(&uri))
        .expect("invariant violated: compiler source maps must be valid JSON"))
}

fn source_errors(
    workspace: &Workspace,
    sources: &[FileId],
) -> Result<Vec<ProjectError>, QueryError> {
    let mut errors = Vec::new();
    for &file_id in sources {
        let collected = workspace
            .analyzer()
            .with_context(|context| iris_analysis::diagnostics::implementation(context, file_id));
        let collected = match collected {
            Ok(collected) => collected,
            Err(iris_analysis::AnalyzerError::QueryError(error)) => return Err(error),
            Err(_) => continue,
        };
        for diagnostic in collected.diagnostics {
            if diagnostic.severity == Some(DiagnosticSeverity::Error) {
                errors.push(ProjectError { uri: collected.uri.to_string(), diagnostic });
            }
        }
    }
    Ok(errors)
}

pub fn emit(workspace: &Workspace) -> Result<Emitted, QueryError> {
    let sources = workspace.project_sources().collect::<Vec<_>>();
    let errors = source_errors(workspace, &sources)?;
    if !errors.is_empty() {
        return Ok(Emitted::Failed { errors });
    }

    let engine = &workspace.engine;
    let mut modules = Vec::new();
    let mut files = Vec::new();
    let mut requires_runtime = false;
    let mut pending: Vec<FileId> = sources.clone();
    let mut visited = HashSet::new();
    while let Some(file_id) = pending.pop() {
        if !visited.insert(file_id) {
            continue;
        }
        let Ok(module) = engine.javascript(file_id)? else {
            continue;
        };
        pending.extend(module.dependencies().iter().copied());
        requires_runtime |= module.requires_runtime();
        let path = module.filename();
        if sources.contains(&file_id)
            && let Some(uri) = workspace.files.source_path(file_id)
        {
            let name = module.name().to_string();
            modules.push(EmittedModule { name, uri: uri.to_string(), path: path.clone() });
        }
        let map = Some(source_map(workspace, file_id)?);
        files.push(EmittedFile { path, text: module.files().index_source().to_string(), map });
        if let Some(kind) = module.files().foreign_kind() {
            let foreign = engine.foreign_file(file_id).and_then(|id| engine.foreign_content(id));
            let path = javascript::foreign_module_filename(module.name(), kind);
            files.push(EmittedFile {
                path,
                text: foreign.as_deref().unwrap_or_default().to_string(),
                map: None,
            });
        }
    }
    if requires_runtime {
        let path = javascript::runtime_filename().to_string();
        files.push(EmittedFile { path, text: javascript::runtime_source().to_string(), map: None });
    }
    modules.sort_by(|a, b| a.name.cmp(&b.name));
    files.sort_by(|a, b| a.path.cmp(&b.path));
    Ok(Emitted::Emitted { modules, files })
}
