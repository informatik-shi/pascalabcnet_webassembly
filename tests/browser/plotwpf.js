import { PascalABC } from "../../dist/pascalabc-web.js";

const progressElement = document.getElementById("progress");
const resultElement = document.getElementById("result");

try {
  PascalABC.attachCanvas(document.getElementById("graphics"));
  await PascalABC.init({ initTimeout: 600000 });
  const run = await PascalABC.run(`
uses PlotWPF;
begin
  var grid := new GridWPF(1, 2, 10);

  var line := new LineGraphWPF(-Pi, Pi, x -> Sin(x), Colors.RoyalBlue);
  line.Title := 'Waves';
  line.Graph[0].Thickness := 3;
  line.AddLineGraph(-Pi, Pi, x -> Cos(x), Colors.Coral);
  line.Graph[1].ChangeData(-Pi, Pi, x -> Cos(x) * 0.8);

  var markers := new MarkerGraphWPF(
    Arr(1.0, 2.0, 3.0, 4.0), Arr(2.0, 5.0, 3.0, 6.0),
    Colors.Green, MarkerType.Diamond, 12);
  markers.Title := 'Points';
  markers.PlotRect := Rect(0.5, 1, 4, 6);
end.
`, { timeout: 30000 });

  const canvas = document.getElementById("graphics");
  const context = canvas.getContext("2d");
  const pixels = context.getImageData(0, 0, canvas.width, canvas.height).data;
  let coloredPixels = 0;
  for (let index = 0; index < pixels.length; index += 4) {
    const red = pixels[index];
    const green = pixels[index + 1];
    const blue = pixels[index + 2];
    if (Math.max(red, green, blue) - Math.min(red, green, blue) > 35)
      coloredPixels++;
  }

  const passed = run.success
    && canvas.width >= 640
    && canvas.height >= 420
    && coloredPixels > 300;
  progressElement.textContent = passed ? "PASS" : "FAIL";
  resultElement.textContent = JSON.stringify({
    passed,
    run,
    coloredPixels,
    canvas: { width: canvas.width, height: canvas.height },
    renderer: context ? "2d" : null
  }, null, 2);
} catch (error) {
  progressElement.textContent = "FATAL";
  resultElement.textContent = JSON.stringify({ fatal: String(error), stack: error?.stack }, null, 2);
}
