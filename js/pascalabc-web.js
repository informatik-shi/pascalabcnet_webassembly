import { CanvasGraphicsRenderer } from "./pascalabc-graphics.js";

const DEFAULT_TIMEOUT = 3000;
const DEFAULT_INIT_TIMEOUT = 120000;
const DEFAULT_COMPILE_TIMEOUT = 30000;

class PascalABCTimeoutError extends Error {
  constructor(timeout) {
    super(`PascalABC.NET execution exceeded ${timeout} ms.`);
    this.name = "PascalABCTimeoutError";
    this.timeout = timeout;
  }
}

class PascalABCClient {
  constructor() {
    this.worker = null;
    this.readyPromise = null;
    this.pending = new Map();
    this.nextId = 1;
    this.version = null;
    this.options = {};
    this.graphicsRenderer = null;
  }

  async init(options = {}) {
    if (this.readyPromise) return this.readyPromise;
    this.options = { ...this.options, ...options };
    const workerUrl = this.options.workerUrl
      ? new URL(this.options.workerUrl, document.baseURI)
      : new URL("./pascalabc-worker.js", import.meta.url);
    const baseUrl = this.options.baseUrl
      ? new URL(this.options.baseUrl, document.baseURI).href
      : new URL("./", workerUrl).href;

    this.worker = new Worker(workerUrl, { type: "module", name: "PascalABC.NET" });
    this.worker.onmessage = (event) => this.#onMessage(event.data);
    this.worker.onerror = (event) => this.#terminate(new Error(event.message || "PascalABC.NET worker failed."));

    this.readyPromise = this.#waitForReady(this.options.initTimeout ?? DEFAULT_INIT_TIMEOUT)
      .then(() => this.#request({ operation: "init", baseUrl }, this.options.initTimeout ?? DEFAULT_INIT_TIMEOUT))
      .then((result) => {
        if (!result.success) throw new Error(result.stderr || "PascalABC.NET initialization failed.");
        this.version = result.version;
        return this;
      })
      .catch((error) => {
        this.#terminate(error);
        throw error;
      });
    return this.readyPromise;
  }

  async compile(code, options = {}) {
    await this.init();
    return this.#withTimeoutResult(
      () => this.#request({ operation: "compile", code }, options.timeout ?? DEFAULT_COMPILE_TIMEOUT),
      options.timeout ?? DEFAULT_COMPILE_TIMEOUT
    );
  }

  async run(code, options = {}) {
    await this.init();
    const compileTimeout = options.compileTimeout ?? DEFAULT_COMPILE_TIMEOUT;
    const compilation = await this.#withTimeoutResult(
      () => this.#request({ operation: "compile", code }, compileTimeout),
      compileTimeout
    );
    if (!compilation.success) return compilation;

    const timeout = options.timeout ?? DEFAULT_TIMEOUT;
    const execution = await this.#withTimeoutResult(
      () => this.#request({
        operation: "execute",
        artifactId: compilation.artifactId,
        stdin: options.stdin ?? ""
      }, timeout),
      timeout
    );
    if (execution.timedOut) {
      execution.compileTime = compilation.compileTime;
      execution.artifactId = compilation.artifactId;
      execution.assemblyBytes = compilation.assemblyBytes;
    }
    return execution;
  }

  async check(code, tests, options = {}) {
    await this.init();
    const timeout = options.timeout ?? Math.max(DEFAULT_TIMEOUT, tests.length * DEFAULT_TIMEOUT);
    return this.#withTimeoutResult(
      () => this.#request({
        operation: "check",
        code,
        tests,
        comparison: {
          trimTrailingWhitespace: options.trimTrailingWhitespace ?? true,
          normalizeNewlines: options.normalizeNewlines ?? true,
          ignoreTrailingNewline: options.ignoreTrailingNewline ?? false
        }
      }, timeout),
      timeout
    );
  }

  stop() {
    this.#terminate(new Error("PascalABC.NET worker was stopped."));
  }

  attachCanvas(canvas, options = {}) {
    this.graphicsRenderer = new CanvasGraphicsRenderer(canvas, options);
    return this.graphicsRenderer;
  }

  detachCanvas() {
    const renderer = this.graphicsRenderer;
    this.graphicsRenderer = null;
    return renderer;
  }

  async #withTimeoutResult(operation, timeout) {
    try {
      return await operation();
    } catch (error) {
      if (!(error instanceof PascalABCTimeoutError)) throw error;
      return {
        success: false,
        timedOut: true,
        stdout: "",
        stderr: error.message,
        exitCode: 124,
        compileTime: 0,
        executionTime: timeout,
        diagnostics: []
      };
    }
  }

  #waitForReady(timeout) {
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new PascalABCTimeoutError(timeout)), timeout);
      this.pending.set("ready", { resolve, reject, timer });
    });
  }

  #request(request, timeout) {
    if (!this.worker) return Promise.reject(new Error("PascalABC.NET is not initialized."));
    const id = this.nextId++;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        const error = new PascalABCTimeoutError(timeout);
        this.pending.delete(id);
        this.#terminate(error);
        reject(error);
      }, timeout);
      this.pending.set(id, { resolve, reject, timer });
      this.worker.postMessage({ id, request });
    });
  }

  #onMessage(message) {
    if (message.type === "graphics") {
      this.graphicsRenderer?.handle(message.envelope);
      return;
    }
    if (message.type === "ready") {
      const pending = this.pending.get("ready");
      if (pending) {
        clearTimeout(pending.timer);
        this.pending.delete("ready");
        pending.resolve();
      }
      return;
    }
    if (message.type === "startup-error") {
      this.#failAll(new Error(message.error));
      return;
    }
    const pending = this.pending.get(message.id);
    if (!pending) return;
    clearTimeout(pending.timer);
    this.pending.delete(message.id);
    if (message.error) pending.reject(new Error(message.error));
    else pending.resolve(message.result);
  }

  #failAll(error) {
    for (const pending of this.pending.values()) {
      clearTimeout(pending.timer);
      pending.reject(error);
    }
    this.pending.clear();
  }

  #terminate(error) {
    if (this.worker) this.worker.terminate();
    this.worker = null;
    this.readyPromise = null;
    this.version = null;
    this.#failAll(error);
  }
}

export const PascalABC = new PascalABCClient();
export { CanvasGraphicsRenderer, PascalABCClient, PascalABCTimeoutError };
