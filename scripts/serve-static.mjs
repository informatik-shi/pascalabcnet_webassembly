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
  try {
    const requestPath = decodeURIComponent(new URL(request.url, "http://localhost").pathname);
    if (requestPath === "/") {
      response.writeHead(302, {
        "Location": "/demo/",
        "Cache-Control": "no-store"
      }).end();
      return;
    }

    const relativePath = normalize(requestPath).replace(/^([/\\])+/, "");
    let filePath = resolve(join(root, relativePath));

    if (filePath !== root && !filePath.startsWith(`${root}${sep}`)) {
      response.writeHead(403).end("Forbidden");
      return;
    }

    if (statSync(filePath).isDirectory()) filePath = join(filePath, "index.html");
    if (!statSync(filePath).isFile()) throw new Error("Not a file");

    let contentEncoding = extname(filePath) === ".br" ? "br" : undefined;
    let sourceExtension = contentEncoding ? extname(filePath.slice(0, -3)) : extname(filePath);
    if (!contentEncoding && request.headers["accept-encoding"]?.includes("br") && existsSync(`${filePath}.br`)) {
      filePath = `${filePath}.br`;
      contentEncoding = "br";
    }
    if (!statSync(filePath).isFile()) throw new Error("Not a file");

    response.writeHead(200, {
      "Content-Type": mime[sourceExtension] ?? "application/octet-stream",
      ...(contentEncoding ? { "Content-Encoding": contentEncoding } : {}),
      "Vary": "Accept-Encoding",
      "Cache-Control": "no-store"
    });

    if (request.method === "HEAD") {
      response.end();
      return;
    }

    const stream = createReadStream(filePath);
    stream.on("error", () => response.end());
    stream.pipe(response);
  } catch {
    if (!response.headersSent) response.writeHead(404);
    response.end("Not found");
  }
}).listen(port, "127.0.0.1", () => {
  process.stdout.write(`serving ${root} on http://127.0.0.1:${port}\n`);
});
