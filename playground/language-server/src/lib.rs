//! The Iris language server for the playground, built from the compiler's own analysis crates.
//!
//! It speaks LSP as JSON strings, one message at a time, and runs on the single thread of a Web
//! Worker. A panic aborts the instance, so the host restarts it and replays its documents.

mod capabilities;
mod emit;
mod protocol;
mod requests;
mod server;
mod workspace;

use wasm_bindgen::prelude::*;

pub use server::Server;

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(js_namespace = console, js_name = error)]
    fn console_error(message: &str);
}

#[wasm_bindgen(start)]
pub fn start() {
    std::panic::set_hook(Box::new(|info| console_error(&info.to_string())));
}

#[wasm_bindgen]
pub struct LanguageServer {
    server: Server,
}

#[wasm_bindgen]
impl LanguageServer {
    #[wasm_bindgen(constructor)]
    pub fn new() -> LanguageServer {
        LanguageServer { server: Server::default() }
    }

    /// Handles one JSON-RPC message and returns a JSON array of the messages to send back.
    pub fn handle(&mut self, message: &str) -> String {
        let outgoing = match serde_json::from_str(message) {
            Ok(message) => self.server.handle(message),
            Err(error) => vec![serde_json::json!({
                "jsonrpc": "2.0",
                "id": null,
                "error": { "code": -32700, "message": error.to_string() },
            })],
        };
        serde_json::to_string(&outgoing).expect("invariant violated: messages must serialize")
    }

    /// Collects the next queued diagnostics and returns a `publishDiagnostics` notification, or
    /// `undefined` when nothing is queued. Call it while no messages are waiting.
    #[wasm_bindgen(js_name = nextDiagnostics)]
    pub fn next_diagnostics(&mut self) -> Option<String> {
        let notification = self.server.next_diagnostics()?;
        Some(notification.to_string())
    }
}

#[wasm_bindgen]
impl LanguageServer {
    /// The text of any source the server knows, such as a package or Prim module that the editor
    /// opens read-only, or `undefined`.
    #[wasm_bindgen(js_name = readSource)]
    pub fn read_source(&self, uri: &str) -> Option<String> {
        self.server.read_source(uri)
    }
}

impl Default for LanguageServer {
    fn default() -> LanguageServer {
        LanguageServer::new()
    }
}
