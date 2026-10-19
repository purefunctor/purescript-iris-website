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

use crate::workspace::Workspace;

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
}

pub fn emit(workspace: &Workspace) -> Result<Emitted, QueryError> {
    let sources = workspace.project_sources().collect::<Vec<_>>();
    let mut errors = Vec::new();
    for &file_id in &sources {
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
        files.push(EmittedFile { path, text: module.files().index_source().to_string() });
        if let Some(kind) = module.files().foreign_kind() {
            let foreign = engine.foreign_file(file_id).and_then(|id| engine.foreign_content(id));
            let path = javascript::foreign_module_filename(module.name(), kind);
            files.push(EmittedFile {
                path,
                text: foreign.as_deref().unwrap_or_default().to_string(),
            });
        }
    }
    if requires_runtime {
        let path = javascript::runtime_filename().to_string();
        files.push(EmittedFile { path, text: javascript::runtime_source().to_string() });
    }
    modules.sort_by(|a, b| a.name.cmp(&b.name));
    files.sort_by(|a, b| a.path.cmp(&b.path));
    Ok(Emitted::Emitted { modules, files })
}
