import { existsSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { resolve } from "node:path";

const root = resolve(import.meta.dirname, "..");
const windows = process.platform === "win32";
const localDotnet = resolve(root, ".dotnet", windows ? "dotnet.exe" : "dotnet");
const dotnet = existsSync(localDotnet) ? localDotnet : "dotnet";
const dotnetProbe = spawnSync(dotnet, ["--version"], { encoding: "utf8" });

if (dotnetProbe.error?.code === "ENOENT") {
  console.error([
    "The .NET 10 SDK was not found in PATH.",
    "Install the SDK first, reopen the terminal, then run:",
    "  dotnet --version",
    "  dotnet workload install wasm-tools",
    "  npm run build"
  ].join("\n"));
  process.exit(127);
}
if (dotnetProbe.status !== 0) {
  process.stderr.write(dotnetProbe.stderr ?? "Unable to run dotnet.\n");
  process.exit(dotnetProbe.status ?? 1);
}

const command = windows ? "powershell" : "bash";
const args = windows
  ? ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "scripts/build.ps1"]
  : ["scripts/build.sh"];
const environment = { ...process.env };
if (existsSync(localDotnet)) {
  environment.DOTNET_CMD = localDotnet;
  environment.DOTNET_ROOT = resolve(root, ".dotnet");
}

const result = spawnSync(command, args, {
  cwd: root,
  env: environment,
  stdio: "inherit"
});
if (result.error?.code === "ENOENT") {
  console.error(`${command} is required to run the build on this platform.`);
  process.exit(127);
}
process.exit(result.status ?? 1);
