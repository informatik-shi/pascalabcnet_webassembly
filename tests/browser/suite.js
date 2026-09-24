import { PascalABC } from "../../dist/pascalabc-web.js";

const progressElement = document.getElementById("progress");
const resultElement = document.getElementById("result");
const normalize = value => value.replaceAll("\r\n", "\n").replaceAll("\r", "\n");

try {
  const cases = await fetch("../programs/cases.json").then(response => response.json());
  await PascalABC.init({ initTimeout: 600000 });
  const compilerVersion = PascalABC.version;
  const results = [];

  for (const [index, test] of cases.entries()) {
    progressElement.textContent = `${index + 1}/${cases.length}: ${test.file}`;
    const code = await fetch(`../programs/${test.file}`).then(response => response.text());
    const tasks = test.tasks
      ? await fetch(`../programs/${test.tasks}`).then(response => response.text())
      : null;
    const timeout = test.expect === "timeout" ? 750 : 30000;
    const result = await PascalABC.run(code, {
      stdin: test.stdin ?? "",
      timeout,
      lightPT: tasks ? { tasks, taskName: test.taskName } : undefined
    });
    const passed = test.expect === "compile-error"
      ? !result.success && result.diagnostics?.some(item => item.severity === "error")
      : test.expect === "runtime-error"
        ? !result.success && result.exitCode !== 0 && Boolean(result.stderr)
        : test.expect === "timeout"
          ? result.timedOut === true && result.exitCode === 124
          : result.success
            && normalize(result.stdout) === test.stdout
            && (!tasks || result.lightPT?.passed === true);
    results.push({
      file: test.file,
      passed,
      expected: test.expect ?? test.stdout,
      actual: test.expect ? {
        success: result.success,
        timedOut: result.timedOut,
        exitCode: result.exitCode,
        diagnostics: result.diagnostics?.length ?? 0,
        hasStderr: Boolean(result.stderr)
      } : normalize(result.stdout)
    });
  }

  const failed = results.filter(item => !item.passed);
  progressElement.textContent = failed.length === 0 ? "PASS" : "FAIL";
  resultElement.textContent = JSON.stringify({
    version: compilerVersion,
    passed: results.length - failed.length,
    failed: failed.length,
    failures: failed,
    results
  }, null, 2);
} catch (error) {
  progressElement.textContent = "FATAL";
  resultElement.textContent = JSON.stringify({ fatal: String(error), stack: error?.stack }, null, 2);
}
