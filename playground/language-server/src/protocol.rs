
use serde_json::{Value, json};

pub enum Rejection {
    MethodNotFound(String),
    InvalidParams(String),
    ServerNotInitialized,
    RequestFailed(String),
    ContentModified,
}

impl Rejection {
    fn code_and_message(self) -> (i64, String) {
        match self {
            Rejection::MethodNotFound(method) => (-32601, format!("Unhandled method {method}")),
            Rejection::InvalidParams(message) => (-32602, message),
            Rejection::ServerNotInitialized => (-32002, "Server is not initialized".to_string()),
            Rejection::RequestFailed(message) => (-32803, message),
            Rejection::ContentModified => (-32801, "Content modified".to_string()),
        }
    }
}

pub fn response(id: Value, result: Result<Value, Rejection>) -> Value {
    match result {
        Ok(result) => json!({ "jsonrpc": "2.0", "id": id, "result": result }),
        Err(rejection) => {
            let (code, message) = rejection.code_and_message();
            json!({ "jsonrpc": "2.0", "id": id, "error": { "code": code, "message": message } })
        }
    }
}

pub fn notification(method: &str, params: Value) -> Value {
    json!({ "jsonrpc": "2.0", "method": method, "params": params })
}
