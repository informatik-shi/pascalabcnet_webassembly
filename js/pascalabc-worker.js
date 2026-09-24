import { dotnet } from "./_framework/dotnet.js";

const runtimePromise = (async () => {
  const runtime = await dotnet.create();
  const config = runtime.getConfig();
  const exports = await runtime.getAssemblyExports(config.mainAssemblyName);
  const invoke = exports.PascalABC.Web.Runtime.BrowserCompilerHost.Invoke;
  self.postMessage({ type: "ready" });
  return invoke;
})();

let sandboxLocked = false;

function lockDownBrowserNetwork() {
  if (sandboxLocked) return;
  sandboxLocked = true;
  const denied = () => Promise.reject(new TypeError("Network access is disabled in the PascalABC.Web student sandbox."));
  Object.defineProperty(self, "fetch", {
    value: denied,
    configurable: false,
    writable: false
  });

  // These APIs are not required by the compiler after initialization. Keep
  // them unavailable even if a browser starts exposing more of them in workers.
  for (const name of ["WebSocket", "EventSource", "XMLHttpRequest"])
    if (name in self)
      Object.defineProperty(self, name, { value: undefined, configurable: false, writable: false });
}

self.onmessage = async ({ data }) => {
  const { id, request } = data;
  try {
    const invoke = await runtimePromise;
    const json = await invoke(JSON.stringify(request));
    const result = JSON.parse(json);
    if (request.operation === "init" && result.success)
      lockDownBrowserNetwork();
    self.postMessage({ id, result });
  } catch (error) {
    self.postMessage({
      id,
      error: error instanceof Error ? `${error.message}\n${error.stack ?? ""}` : String(error)
    });
  }
};

runtimePromise.catch((error) => {
  self.postMessage({
    type: "startup-error",
    error: error instanceof Error ? `${error.message}\n${error.stack ?? ""}` : String(error)
  });
});
