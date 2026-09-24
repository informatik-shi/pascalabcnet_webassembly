import { createReadStream, existsSync, statSync } from "node:fs";
import { createServer } from "node:http";
import { extname, join, normalize, resolve, sep } from "node:path";

const root = resolve(process.argv[2] ?? ".");
const port = Number(process.argv[3] ?? 8080);
const mime = {
  ".br": "application/octet-stream",
  ".css": "text/css; charset=utf-8",
  ".dll": "application/octet-stream",
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".wasm": "application/wasm"
};

createServer((request, response) => {
  const requestPath = decodeURIComponent(new URL(request.url, "http://localhost").pathname);
  const relativePath = normalize(requestPath).replace(/^([/\\])+/, "");
  let filePath = resolve(join(root, relativePath));

  if (filePath !== root && !filePath.startsWith(`${root}${sep}`)) {
    response.writeHead(403).end("Forbidden");
    return;
  }

  try {
    if (statSync(filePath).isDirectory()) filePath = join(filePath, "index.html");
    let contentEncoding = extname(filePath) === ".br" ? "br" : undefined;
    let sourceExtension = contentEncoding ? extname(filePath.slice(0, -3)) : extname(filePath);
    if (!contentEncoding && request.headers["accept-encoding"]?.includes("br") && existsSync(`${filePath}.br`)) {
      filePath = `${filePath}.br`;
      contentEncoding = "br";
    }
    response.writeHead(200, {
      "Content-Type": mime[sourceExtension] ?? "application/octet-stream",
      ...(contentEncoding ? { "Content-Encoding": contentEncoding } : {}),
      "Vary": "Accept-Encoding",
      "Cache-Control": "no-store"
    });
    createReadStream(filePath).pipe(response);
  } catch {
    response.writeHead(404).end("Not found");
  }
}).listen(port, "127.0.0.1", () => {
  process.stdout.write(`serving ${root} on http://127.0.0.1:${port}\n`);
});
