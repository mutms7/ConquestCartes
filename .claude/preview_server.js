const http = require("http");
const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..", "web");
const port = 8099;
const mime = {
  ".html": "text/html",
  ".js": "text/javascript",
  ".wasm": "application/wasm",
  ".pck": "application/octet-stream",
  ".png": "image/png",
  ".json": "application/json",
  ".svg": "image/svg+xml",
};

http
  .createServer((req, res) => {
    let p = decodeURIComponent(req.url.split("?")[0]);
    if (p === "/") p = "/index.html";
    const fp = path.join(root, p);
    res.setHeader("Cross-Origin-Opener-Policy", "same-origin");
    res.setHeader("Cross-Origin-Embedder-Policy", "require-corp");
    res.setHeader("Cross-Origin-Resource-Policy", "cross-origin");
    fs.readFile(fp, (err, data) => {
      if (err) {
        res.statusCode = 404;
        res.end("not found");
        return;
      }
      res.setHeader("Content-Type", mime[path.extname(fp)] || "application/octet-stream");
      res.end(data);
    });
  })
  .listen(port, () => console.log("serving web/ on http://localhost:" + port));
