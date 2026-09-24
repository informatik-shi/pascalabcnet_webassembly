import { PascalABC } from "../../dist/pascalabc-web.js";

const progressElement = document.getElementById("progress");
const resultElement = document.getElementById("result");

try {
  PascalABC.attachCanvas(document.getElementById("graphics"));
  await PascalABC.init({ initTimeout: 600000 });
  const run = await PascalABC.run(`
uses Graph3D;
begin
  Window.SetSize(320, 220);
  View3D.ShowGridLines := False;
  View3D.ShowCoordinateSystem := False;
  View3D.BackgroundColor := RGB(15, 23, 42);
  Cube(-1.2, 0, 0, 1.8, Colors.RoyalBlue).Rotate(V3D(0, 0, 1), 25);
  Sphere(1.2, 0, 0, 1, Colors.Gold);
end.
`, { timeout: 30000 });

  await new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)));
  const canvas = document.getElementById("graphics");
  const gl = canvas.getContext("webgl2");
  const pixels = new Uint8Array(canvas.width * canvas.height * 4);
  gl.readPixels(0, 0, canvas.width, canvas.height, gl.RGBA, gl.UNSIGNED_BYTE, pixels);
  let coloredPixels = 0;
  for (let index = 0; index < pixels.length; index += 4)
    if (Math.abs(pixels[index] - 15) > 8 || Math.abs(pixels[index + 1] - 23) > 8 || Math.abs(pixels[index + 2] - 42) > 8)
      coloredPixels++;

  const passed = run.success && coloredPixels > 500;
  progressElement.textContent = passed ? "PASS" : "FAIL";
  resultElement.textContent = JSON.stringify({ passed, run, coloredPixels, renderer: gl ? "webgl2" : null }, null, 2);
} catch (error) {
  progressElement.textContent = "FATAL";
  resultElement.textContent = JSON.stringify({ fatal: String(error), stack: error?.stack }, null, 2);
}
