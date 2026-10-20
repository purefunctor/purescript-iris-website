//! Capability negotiation and the server capabilities.
//!
//! This mirrors `compiler-executable/iris-lsp-workspace/src/capabilities.rs` in the Iris
//! repository, except that the playground has no files to save.

use iris_analysis::AnalyzerCapabilities;
use iris_analysis::position::PositionEncoding;
use lsp_types::*;

pub fn negotiate_analyzer_capabilities(capabilities: &ClientCapabilities) -> AnalyzerCapabilities {
    let workspace_edit =
        capabilities.workspace.as_ref().and_then(|workspace| workspace.workspace_edit.as_ref());
    let honors_rename_annotations = capabilities
        .text_document
        .as_ref()
        .and_then(|text_document| text_document.rename.as_ref())
        .is_some_and(|rename| rename.honors_change_annotations == Some(true));
    let change_annotations = workspace_edit.is_some_and(|workspace_edit| {
        workspace_edit.document_changes == Some(true)
            && workspace_edit.change_annotation_support.is_some()
            && honors_rename_annotations
    });

    let mut negotiated = AnalyzerCapabilities::default();
    if change_annotations {
        negotiated = negotiated.with_change_annotations();
    }
    let markdown_hover = capabilities
        .text_document
        .as_ref()
        .and_then(|text_document| text_document.hover.as_ref())
        .and_then(|hover| hover.content_format.as_ref())
        .and_then(|formats| {
            formats
                .iter()
                .find(|format| matches!(format, MarkupKind::PlainText | MarkupKind::Markdown))
        })
        .is_some_and(|format| format == &MarkupKind::Markdown);
    if markdown_hover {
        negotiated = negotiated.with_markdown_hover();
    }
    negotiated
}

pub fn negotiate_position_encoding(capabilities: &ClientCapabilities) -> PositionEncoding {
    let Some(encodings) =
        capabilities.general.as_ref().and_then(|general| general.position_encodings.as_ref())
    else {
        return PositionEncoding::Utf16;
    };

    if encodings.contains(&PositionEncodingKind::UTF8) {
        PositionEncoding::Utf8
    } else if encodings.contains(&PositionEncodingKind::UTF16) {
        PositionEncoding::Utf16
    } else if encodings.contains(&PositionEncodingKind::UTF32) {
        PositionEncoding::Utf32
    } else {
        PositionEncoding::Utf16
    }
}

pub fn initialize_result(position_encoding: PositionEncoding) -> InitializeResult {
    InitializeResult {
        server_info: Some(ServerInfo {
            name: "iris-playground-language-server".to_string(),
            version: Some(env!("IRIS_SOURCE").to_string()),
        }),
        capabilities: server_capabilities(position_encoding),
    }
}

fn server_capabilities(position_encoding: PositionEncoding) -> ServerCapabilities {
    ServerCapabilities {
        completion_provider: Some(CompletionOptions {
            resolve_provider: Some(true),
            trigger_characters: Some(vec![".".to_string()]),
            all_commit_characters: None,
            work_done_progress_options: WorkDoneProgressOptions { work_done_progress: None },
            completion_item: Some(ServerCompletionItemOptions {
                label_details_support: Some(true),
            }),
        }),
        code_action_provider: Some(CodeActionProvider::CodeActionOptions(CodeActionOptions {
            code_action_kinds: Some(vec![CodeActionKind::QuickFix]),
            ..CodeActionOptions::default()
        })),
        definition_provider: Some(DefinitionProvider::Bool(true)),
        hover_provider: Some(HoverProvider::Bool(true)),
        references_provider: Some(ReferencesProvider::Bool(true)),
        rename_provider: Some(RenameProvider::RenameOptions(RenameOptions {
            prepare_provider: Some(true),
            work_done_progress_options: WorkDoneProgressOptions { work_done_progress: None },
        })),
        document_highlight_provider: Some(DocumentHighlightProvider::Bool(true)),
        workspace_symbol_provider: Some(WorkspaceSymbolProvider::Bool(true)),
        document_symbol_provider: Some(DocumentSymbolProvider::Bool(true)),
        document_formatting_provider: Some(DocumentFormattingProvider::Bool(true)),
        semantic_tokens_provider: Some(SemanticTokensProvider::SemanticTokensOptions(
            SemanticTokensOptions {
                work_done_progress_options: WorkDoneProgressOptions { work_done_progress: None },
                legend: SemanticTokensLegend {
                    token_types: legend(iris_analysis::semantic_tokens::TOKEN_TYPES),
                    token_modifiers: legend(iris_analysis::semantic_tokens::TOKEN_MODIFIERS),
                },
                range: Some(SemanticTokensOptionsRange::Bool(false)),
                full: Some(Full::Bool(true)),
            },
        )),
        text_document_sync: Some(TextDocumentSync::Options(TextDocumentSyncOptions {
            open_close: Some(true),
            change: Some(TextDocumentSyncKind::Incremental),
            ..TextDocumentSyncOptions::default()
        })),
        position_encoding: Some(PositionEncodingKind::from(position_encoding)),
        ..ServerCapabilities::default()
    }
}

fn legend(names: &[impl ToString]) -> Vec<String> {
    names.iter().map(ToString::to_string).collect()
}
