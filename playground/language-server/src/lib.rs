
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

    #[wasm_bindgen(js_name = nextDiagnostics)]
    pub fn next_diagnostics(&mut self) -> Option<String> {
        let notification = self.server.next_diagnostics()?;
        Some(notification.to_string())
    }
}

#[wasm_bindgen]
impl LanguageServer {
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
