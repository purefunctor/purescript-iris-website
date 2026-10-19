//! Analysis requests.
//!
//! This mirrors `analysis_job` and its handlers in the Iris repository's
//! `compiler-executable/iris-lsp-workspace/src/handlers.rs`, minus snapshots and tracing. When the
//! Iris tag changes, compare the two and carry over new requests and changed parameters.

use building::QueryError;
use iris_analysis::AnalyzerError;
use lsp_types::*;
use serde::Serialize;
use serde_json::Value;

use crate::protocol::Rejection;
use crate::workspace::Workspace;

pub fn handle(workspace: &mut Workspace, method: &str, params: Value) -> Result<Value, Rejection> {
    match LspRequestMethod::from(method) {
        DefinitionRequest::METHOD => run::<DefinitionRequest>(workspace, params, definition),
        HoverRequest::METHOD => run::<HoverRequest>(workspace, params, hover),
        CodeActionRequest::METHOD => run::<CodeActionRequest>(workspace, params, code_action),
        CompletionRequest::METHOD => run::<CompletionRequest>(workspace, params, completion),
        CompletionResolveRequest::METHOD => {
            run::<CompletionResolveRequest>(workspace, params, resolve_completion)
        }
        ReferencesRequest::METHOD => run::<ReferencesRequest>(workspace, params, references),
        PrepareRenameRequest::METHOD => {
            run::<PrepareRenameRequest>(workspace, params, prepare_rename)
        }
        RenameRequest::METHOD => run::<RenameRequest>(workspace, params, rename),
        DocumentHighlightRequest::METHOD => {
            run::<DocumentHighlightRequest>(workspace, params, document_highlight)
        }
        WorkspaceSymbolRequest::METHOD => {
            run::<WorkspaceSymbolRequest>(workspace, params, workspace_symbols)
        }
        DocumentSymbolRequest::METHOD => {
            run::<DocumentSymbolRequest>(workspace, params, document_symbols)
        }
        DocumentFormattingRequest::METHOD => formatting_request(workspace, params),
        SemanticTokensRequest::METHOD => {
            run::<SemanticTokensRequest>(workspace, params, semantic_tokens)
        }
        _ => Err(Rejection::MethodNotFound(method.to_string())),
    }
}

fn run<R>(
    workspace: &mut Workspace,
    params: Value,
    handler: impl FnOnce(&mut Workspace, R::Params) -> Result<R::Result, AnalyzerError>,
) -> Result<Value, Rejection>
where
    R: Request,
    R::Result: Serialize,
{
    let params = serde_json::from_value::<R::Params>(params).map_err(|error| {
        Rejection::InvalidParams(format!("Failed to deserialize parameters: {error}"))
    })?;
    let result = handler(workspace, params).map_err(rejection)?;
    Ok(serde_json::to_value(result).expect("invariant violated: results must serialize"))
}

fn rejection(error: AnalyzerError) -> Rejection {
    match error {
        AnalyzerError::QueryError(QueryError::Cancelled) => Rejection::ContentModified,
        AnalyzerError::RenameRejected(message) => Rejection::InvalidParams(message),
        AnalyzerError::Formatting(iris_analysis::formatting::FormatError::InvalidConfig(
            message,
        )) => Rejection::InvalidParams(message.into()),
        error => Rejection::RequestFailed(error.to_string()),
    }
}

/// Turns [`AnalyzerError::NonFatal`] into `item`.
fn on_non_fatal<T>(result: Result<T, AnalyzerError>, item: T) -> Result<T, AnalyzerError> {
    match result {
        Err(AnalyzerError::NonFatal) => Ok(item),
        result => result,
    }
}

fn definition(
    workspace: &mut Workspace,
    parameters: DefinitionParams,
) -> Result<Option<DefinitionResponse>, AnalyzerError> {
    let uri = parameters.text_document_position_params.text_document.uri;
    let position = parameters.text_document_position_params.position;
    let result = workspace
        .analyzer()
        .with_context(|context| iris_analysis::definition::implementation(context, uri, position));
    on_non_fatal(result, None)
}

fn hover(
    workspace: &mut Workspace,
    parameters: HoverParams,
) -> Result<Option<Hover>, AnalyzerError> {
    let uri = parameters.text_document_position_params.text_document.uri;
    let position = parameters.text_document_position_params.position;
    let result = workspace
        .analyzer()
        .with_context(|context| iris_analysis::hover::implementation(context, uri, position));
    on_non_fatal(result, None)
}

fn code_action(
    workspace: &mut Workspace,
    parameters: CodeActionParams,
) -> Result<Option<Vec<CodeActionResponse>>, AnalyzerError> {
    let uri = parameters.text_document.uri;
    let range = parameters.range;
    let action_context = parameters.context;
    let result = workspace.analyzer().with_context(|context| {
        iris_analysis::code_action::implementation(context, uri, range, action_context)
    });
    on_non_fatal(result, None)
}

fn completion(
    workspace: &mut Workspace,
    parameters: CompletionParams,
) -> Result<Option<CompletionResponse>, AnalyzerError> {
    let uri = parameters.text_document_position_params.text_document.uri;
    let position = parameters.text_document_position_params.position;
    let (analyzer, suggestions, _) = workspace.analyzer_with_caches();
    let result = analyzer.with_context(|context| {
        iris_analysis::completion::implementation(context, suggestions, uri, position)
    });
    on_non_fatal(result, None)
}

fn resolve_completion(
    workspace: &mut Workspace,
    item: CompletionItem,
) -> Result<CompletionItem, AnalyzerError> {
    iris_analysis::completion::resolve::implementation(&workspace.engine, item)
        .or_else(|(error, item)| on_non_fatal(Err(error), item))
}

fn references(
    workspace: &mut Workspace,
    parameters: ReferenceParams,
) -> Result<Option<Vec<Location>>, AnalyzerError> {
    let uri = parameters.text_document_position_params.text_document.uri;
    let position = parameters.text_document_position_params.position;
    let result = workspace
        .analyzer()
        .with_context(|context| iris_analysis::references::implementation(context, uri, position));
    on_non_fatal(result, None)
}

fn prepare_rename(
    workspace: &mut Workspace,
    parameters: PrepareRenameParams,
) -> Result<Option<PrepareRenameResult>, AnalyzerError> {
    let uri = parameters.text_document_position_params.text_document.uri;
    let position = parameters.text_document_position_params.position;
    let result = workspace
        .analyzer()
        .with_context(|context| iris_analysis::rename::prepare(context, uri, position));
    on_non_fatal(result, None)
}

fn rename(
    workspace: &mut Workspace,
    parameters: RenameParams,
) -> Result<Option<WorkspaceEdit>, AnalyzerError> {
    let uri = parameters.text_document_position_params.text_document.uri;
    let position = parameters.text_document_position_params.position;
    let new_name = parameters.new_name;
    let result = workspace.analyzer().with_context(|context| {
        iris_analysis::rename::implementation(context, uri, position, new_name)
    });
    on_non_fatal(result, None)
}

fn document_highlight(
    workspace: &mut Workspace,
    parameters: DocumentHighlightParams,
) -> Result<Option<Vec<DocumentHighlight>>, AnalyzerError> {
    let uri = parameters.text_document_position_params.text_document.uri;
    let position = parameters.text_document_position_params.position;
    let result = workspace.analyzer().with_context(|context| {
        iris_analysis::document_highlight::implementation(context, uri, position)
    });
    on_non_fatal(result, None)
}

fn workspace_symbols(
    workspace: &mut Workspace,
    parameters: WorkspaceSymbolParams,
) -> Result<Option<WorkspaceSymbolResponse>, AnalyzerError> {
    let (analyzer, _, symbols) = workspace.analyzer_with_caches();
    let result = analyzer.with_context(|context| {
        iris_analysis::symbols::workspace(context, symbols, &parameters.query)
    });
    on_non_fatal(result, None)
}

fn document_symbols(
    workspace: &mut Workspace,
    parameters: DocumentSymbolParams,
) -> Result<Option<DocumentSymbolResponse>, AnalyzerError> {
    let uri = parameters.text_document.uri;
    let result =
        workspace.analyzer().with_context(|context| iris_analysis::symbols::document(context, uri));
    on_non_fatal(result, None)
}

fn formatting_request(workspace: &mut Workspace, params: Value) -> Result<Value, Rejection> {
    let line_width = params.get("options").and_then(|options| options.get("lineWidth"));
    let parse_width = |value: &Value| {
        let width = value.as_u64().and_then(|width| usize::try_from(width).ok());
        width
            .filter(|&width| width > 0)
            .ok_or_else(|| Rejection::InvalidParams("lineWidth must be a positive integer".into()))
    };
    let line_width = line_width.map(parse_width).transpose()?;
    run::<DocumentFormattingRequest>(workspace, params, |workspace, parameters| {
        formatting(workspace, parameters, line_width)
    })
}

fn formatting(
    workspace: &mut Workspace,
    parameters: DocumentFormattingParams,
    line_width: Option<usize>,
) -> Result<Option<Vec<TextEdit>>, AnalyzerError> {
    let uri = parameters.text_document.uri;
    let defaults = iris_analysis::formatting::Config::default();
    let config = iris_analysis::formatting::Config {
        line_width: line_width.unwrap_or(defaults.line_width),
        indent_width: parameters.options.tab_size as usize,
        ..defaults
    };
    config.validate()?;
    let result = workspace
        .analyzer()
        .with_context(|context| iris_analysis::formatting::implementation(context, uri, &config));
    on_non_fatal(result, None)
}

fn semantic_tokens(
    workspace: &mut Workspace,
    parameters: SemanticTokensParams,
) -> Result<Option<SemanticTokens>, AnalyzerError> {
    let uri = parameters.text_document.uri;
    let result = workspace
        .analyzer()
        .with_context(|context| iris_analysis::semantic_tokens::implementation(context, uri));
    on_non_fatal(result, None)
}
