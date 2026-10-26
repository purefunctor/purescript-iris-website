
const RESTART_LIMIT = 3;
const RESTART_WINDOW = 60_000;

export class LanguageClient {
  #createWorker;
  #server;
  #handlers;
  #packages = [];
  #worker;
  #nextId = 1;
  #pending = new Map();
  #reads = new Map();
  #crashes = [];
  capabilities = {};
  info = null;

  constructor({ createWorker, server, handlers }) {
    this.#createWorker = createWorker;
    this.#server = server;
    this.#handlers = handlers;
  }

  async start(packages = this.#packages) {
    this.#packages = packages;
    this.#handlers.onStatus({ status: this.info ? "restarting" : "starting" });
    const worker = this.#createWorker();
    this.#worker = worker;
    const started = new Promise((resolve, reject) => {
      worker.onmessage = ({ data }) => {
        if (data.type === "started") resolve(data);
        else if (data.type === "progress") this.#handlers.onProgress(data);
        else if (data.type === "failed") reject(Object.assign(new Error(data.error), { startup: true }));
        else if (data.type === "crashed") reject(new Error(data.error));
        else this.#receive(data);
      };
      worker.onerror = (event) => reject(new Error(event.message || "The language server worker failed to load"));
    });
    worker.postMessage({ type: "start", server: this.#server, packages });
    try {
      this.info = await started;
    } catch (error) {
      if (!error.startup) return this.#crash(error);
      this.dispose();
      this.#handlers.onStatus({ status: "failed", message: error.message });
      return null;
    }
    worker.onmessage = ({ data }) => this.#receive(data);
    worker.onerror = (event) => this.#crash(new Error(event.message));
    const initialized = await this.request("initialize", {
      processId: null,
      rootUri: "file:///project/",
      capabilities: {
        general: { positionEncodings: ["utf-16"] },
        textDocument: {
          hover: { contentFormat: ["markdown", "plaintext"] },
          completion: { completionItem: { snippetSupport: false, labelDetailsSupport: true } },
          rename: { prepareSupport: true },
        },
      },
    });
    this.capabilities = initialized.capabilities;
    this.notify("initialized", {});
    this.#handlers.onStatus({ status: "ready", server: this.info.server });
    return this.info;
  }

  request(method, params, signal) {
    const id = this.#nextId++;
    return new Promise((resolve, reject) => {
      this.#pending.set(id, { resolve, reject });
      this.#post({ type: "lsp", message: { jsonrpc: "2.0", id, method, params } });
      signal?.addEventListener("abort", () => {
        if (!this.#pending.has(id)) return;
        this.#post({ type: "lsp", message: { jsonrpc: "2.0", method: "$/cancelRequest", params: { id } } });
      });
    });
  }

  notify(method, params) {
    this.#post({ type: "lsp", message: { jsonrpc: "2.0", method, params } });
  }

  readSource(uri) {
    const id = this.#nextId++;
    return new Promise((resolve) => {
      this.#reads.set(id, resolve);
      this.#post({ type: "read", id, uri });
    });
  }

  async restart(packages) {
    this.#stop();
    const info = await this.start(packages);
    if (info) await this.#handlers.onRestart();
    return info;
  }

  dispose() {
    this.#worker?.terminate();
    this.#worker = null;
  }

  #post(message) {
    this.#worker?.postMessage(message);
  }

  #receive(data) {
    switch (data.type) {
      case "lsp":
        return this.#receiveMessage(data.message);
      case "read": {
        this.#reads.get(data.id)?.(data.text);
        this.#reads.delete(data.id);
        return;
      }
      case "crashed":
        return this.#crash(new Error(data.error));
    }
  }

  #receiveMessage(message) {
    if (message.method) {
      this.#handlers.onNotification(message.method, message.params);
      return;
    }
    const pending = this.#pending.get(message.id);
    if (!pending) return;
    this.#pending.delete(message.id);
    if (message.error) {
      const error = new Error(message.error.message);
      error.code = message.error.code;
      pending.reject(error);
    } else {
      pending.resolve(message.result);
    }
  }

  #stop() {
    this.dispose();
    const stopped = new Error("The language server restarted");
    stopped.code = -32800;
    for (const { reject } of this.#pending.values()) reject(stopped);
    for (const resolve of this.#reads.values()) resolve(null);
    this.#pending.clear();
    this.#reads.clear();
  }

  async #crash(error) {
    console.error("The playground language server stopped.", error);
    this.#stop();
    const now = Date.now();
    this.#crashes = [...this.#crashes.filter((time) => now - time < RESTART_WINDOW), now];
    if (this.#crashes.length > RESTART_LIMIT) {
      this.#handlers.onStatus({ status: "failed", message: String(error.message ?? error) });
      return;
    }
    this.#handlers.onStatus({ status: "restarting" });
    await new Promise((resolve) => setTimeout(resolve, 250 * this.#crashes.length));
    const info = await this.start();
    if (info) await this.#handlers.onRestart();
  }
}
