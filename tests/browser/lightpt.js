import { PascalABC } from "../../dist/pascalabc-web.js";

const progressElement = document.getElementById("progress");
const resultElement = document.getElementById("result");

try {
  await PascalABC.init({ initTimeout: 600000 });
  const [program, tasks] = await Promise.all([
    fetch("../lightpt/Program.pas").then(response => response.text()),
    fetch("../lightpt/Tasks.pas").then(response => response.text())
  ]);
  const lightPT = { tasks, taskName: "CountDivisibleByFour" };
  const run = await PascalABC.run(program, { timeout: 30000, lightPT });

  const wrong = await PascalABC.run(`
begin
  Println(2);
end.
`, { timeout: 30000, lightPT });

  const afterLightPT = await PascalABC.run(`
begin
  Println('обычный вывод восстановлен');
end.
`, { timeout: 30000 });

  const passed = run.success
    && !program.includes("LightPT")
    && run.stdout.includes("3")
    && run.stdout.includes("LightPT: задание выполнено")
    && run.lightPT?.checked
    && run.lightPT.passed
    && wrong.success
    && wrong.lightPT?.checked
    && !wrong.lightPT.passed
    && wrong.lightPT.status === "BadSolution"
    && !wrong.stdout.includes("ожидалось")
    && afterLightPT.success
    && afterLightPT.stdout === "обычный вывод восстановлен\n";
  progressElement.textContent = passed ? "PASS" : "FAIL";
  resultElement.textContent = JSON.stringify({ passed, run, wrong, afterLightPT }, null, 2);
} catch (error) {
  progressElement.textContent = "FATAL";
  resultElement.textContent = JSON.stringify({ fatal: String(error), stack: error?.stack }, null, 2);
}
