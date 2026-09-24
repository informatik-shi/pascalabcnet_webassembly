import { PascalABC } from "../../dist/pascalabc-web.js";

const canvas = document.getElementById("graphics");
const progressElement = document.getElementById("progress");
const resultElement = document.getElementById("result");

function pixelAt(x, y) {
  const context = canvas.getContext("2d");
  const scale = canvas.width / 320;
  return [...context.getImageData(Math.round(x * scale), Math.round(y * scale), 1, 1).data];
}

try {
  PascalABC.attachCanvas(canvas);
  await PascalABC.init({ initTimeout: 600000 });
  const run = await PascalABC.run(`
uses GraphWPF;
begin
  Window.SetSize(320, 200);
  Window.Clear(RGB(12, 34, 56));
  FillRectangle(20, 20, 100, 60, RGB(220, 40, 60));
end.
`, { timeout: 30000 });

  const background = pixelAt(5, 5);
  const rectangle = pixelAt(25, 25);
  const passed = run.success
    && background.slice(0, 3).join(",") === "12,34,56"
    && rectangle.slice(0, 3).join(",") === "220,40,60";

  progressElement.textContent = passed ? "PASS" : "FAIL";
  resultElement.textContent = JSON.stringify({ passed, run, background, rectangle }, null, 2);
} catch (error) {
  progressElement.textContent = "FATAL";
  resultElement.textContent = JSON.stringify({ fatal: String(error), stack: error?.stack }, null, 2);
}
