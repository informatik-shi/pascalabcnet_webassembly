import { PascalABC } from "../../dist/pascalabc-web.js";

const resultElement = document.getElementById("result");
let mainThreadTicks = 0;
const heartbeat = setInterval(() => mainThreadTicks++, 10);

try {
  await PascalABC.init({ initTimeout: 600000 });
  const started = performance.now();
  const result = await PascalABC.run(`begin
  while true do
  begin
  end;
end.`, { timeout: 500 });
  clearInterval(heartbeat);
  resultElement.textContent = JSON.stringify({
    ...result,
    elapsed: performance.now() - started,
    mainThreadTicks,
    uiResponsive: mainThreadTicks > 5
  }, null, 2);
} catch (error) {
  clearInterval(heartbeat);
  resultElement.textContent = JSON.stringify({
    fatal: String(error),
    stack: error?.stack,
    mainThreadTicks
  }, null, 2);
}
