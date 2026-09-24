import { PascalABC } from "../../dist/pascalabc-web.js";

const resultElement = document.getElementById("result");
try {
  await PascalABC.init({ initTimeout: 1000000000 });
  const code = `begin
  var a := ReadInteger;
  var b := ReadInteger;
  Println(a + b);
end.`;
  const run = await PascalABC.run(code, { stdin: "20\n22\n", timeout: 1000000000 });
  const check = await PascalABC.check(code, [
    { input: "2\n3\n", expected: "5\n" },
    { input: "10\n20\n", expected: "30\n" }
  ], { timeout: 1000000000 });
  resultElement.textContent = JSON.stringify({ version: PascalABC.version, run, check }, null, 2);
} catch (error) {
  resultElement.textContent = JSON.stringify({ fatal: String(error), stack: error?.stack }, null, 2);
}
