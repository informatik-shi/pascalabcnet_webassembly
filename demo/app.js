import { PascalABC } from "../dist/pascalabc-web.js";

const elements = Object.fromEntries(
  ["version", "code", "input", "run", "stop", "check", "status", "output", "diagnostics", "tests", "task", "mode-run", "mode-task", "load-graphics", "load-plotwpf", "load-graphics3d", "load-lightpt", "graphics", "graphics-title", "graphics-renderer", "graphics-canvas"]
    .map(id => [id, document.getElementById(id)])
);

const graphicsExample = `uses GraphWPF;

begin
  Window.SetSize(800, 500);
  Window.Title := 'GraphWPF в браузере';
  Window.Clear(Colors.WhiteSmoke);

  Pen.Width := 3;
  Pen.Color := Colors.RoyalBlue;
  Brush.Color := RGB(210, 230, 255);
  Rectangle(60, 70, 250, 150);

  Brush.Color := Colors.Gold;
  Circle(440, 145, 75);
  Line(60, 280, 680, 280, Colors.DarkGray);

  var points := Arr(Pnt(540, 370), Pnt(610, 310),
    Pnt(680, 370), Pnt(650, 440), Pnt(570, 440));
  Brush.Color := Colors.LightGreen;
  Polygon(points);

  Font.Size := 26;
  Font.Color := Colors.DarkRed;
  TextOut(185, 145, 'PascalABC.NET', Alignment.Center);
  Font.Size := 18;
  Font.Color := Colors.Black;
  TextOut(440, 145, 'Canvas 2D', Alignment.Center);
end.`;

const plotWPFExample = `uses PlotWPF;

begin
  var grid := new GridWPF(1, 2, 10);

  var waves := new LineGraphWPF(-Pi, Pi, x -> Sin(x), Colors.RoyalBlue);
  waves.Title := 'Синус и косинус';
  waves.Graph[0].Thickness := 3;
  waves.AddLineGraph(-Pi, Pi, x -> Cos(x), Colors.Coral);

  var points := new MarkerGraphWPF(
    Arr(1.0, 2.0, 3.0, 4.0, 5.0),
    Arr(2.0, 5.0, 3.0, 7.0, 4.0),
    Colors.Green, MarkerType.Diamond, 10);
  points.Title := 'Наблюдения';
  points.AddLineGraph(
    Arr(1.0, 2.0, 3.0, 4.0, 5.0),
    Arr(2.0, 5.0, 3.0, 7.0, 4.0), Colors.LightGreen);
end.`;

let lightPTAssignment = null;

const graphics3DExample = `uses Graph3D;

begin
  Window.SetSize(800, 500);
  Window.Title := 'Graph3D в браузере';
  View3D.BackgroundColor := RGB(15, 23, 42);

  var cube := Cube(-2.7, 0, 1.1, 2.2, Colors.RoyalBlue);
  cube.Rotate(V3D(0, 0, 1), 25);
  Sphere(0.2, 0, 1.2, 1.2, Colors.Gold);
  Cylinder(3, 0, 1.3, 2.6, 0.85, Colors.LightGreen);
  Cone(0, 3.2, 1.4, 2.8, 1.2, Colors.Coral);
end.`;

const assignmentTests = [
  { input: "2\n3\n", expected: "5\n" },
  { input: "10\n20\n", expected: "30\n" },
  { input: "-1\n16\n", expected: "15\n" }
];

function setBusy(busy, text = "") {
  elements.run.disabled = busy;
  elements.check.disabled = busy;
  elements.status.textContent = text;
}

function showDiagnostics(diagnostics = []) {
  const list = elements.diagnostics.querySelector("ol");
  list.replaceChildren(...diagnostics.map(item => {
    const li = document.createElement("li");
    li.textContent = `${item.line}:${item.column} ${item.message}`;
    li.addEventListener("click", () => focusLine(item.line));
    return li;
  }));
  elements.diagnostics.hidden = diagnostics.length === 0;
}

function focusLine(line) {
  const textarea = elements.code;
  const lines = textarea.value.split("\n");
  const start = lines.slice(0, Math.max(0, line - 1)).reduce((sum, value) => sum + value.length + 1, 0);
  textarea.focus();
  textarea.setSelectionRange(start, start + (lines[line - 1]?.length ?? 0));
}

async function run() {
  setBusy(true, "Компиляция и выполнение…");
  showDiagnostics();
  elements.output.textContent = "";
  elements.graphics.hidden = true;
  try {
    const result = await PascalABC.run(elements.code.value, {
      stdin: elements.input.value,
      timeout: 3000,
      lightPT: lightPTAssignment
    });
    elements.output.textContent = result.stdout || result.stderr;
    showDiagnostics(result.diagnostics);
    elements.status.textContent = result.timedOut
      ? "Остановлено по timeout"
      : result.lightPT?.checked
        ? result.lightPT.passed ? "LightPT: задание выполнено" : "LightPT: неверное решение"
        : `${result.compileTime.toFixed(0)} мс compile · ${result.executionTime.toFixed(0)} мс run`;
  } catch (error) {
    elements.output.textContent = String(error);
    elements.status.textContent = "Ошибка runtime";
  } finally {
    setBusy(false, elements.status.textContent);
  }
}

async function check() {
  setBusy(true, "Проверка…");
  elements.tests.hidden = false;
  const list = elements.tests.querySelector("ol");
  list.replaceChildren();
  try {
    const result = await PascalABC.check(elements.code.value, assignmentTests, {
      normalizeNewlines: true,
      trimTrailingWhitespace: true,
      ignoreTrailingNewline: false,
      timeout: 12000
    });
    showDiagnostics(result.diagnostics);
    list.replaceChildren(...(result.tests ?? []).map((test, index) => {
      const li = document.createElement("li");
      li.className = test.passed ? "passed" : "failed";
      li.textContent = test.passed
        ? `Тест ${index + 1} ✓`
        : `Тест ${index + 1} ✗ — ожидалось ${JSON.stringify(test.expected)}, получено ${JSON.stringify(test.actual)}`;
      return li;
    }));
    elements.status.textContent = `${result.passed} из ${result.passed + result.failed}`;
  } catch (error) {
    elements.output.textContent = String(error);
  } finally {
    setBusy(false, elements.status.textContent);
  }
}

function selectMode(taskMode) {
  elements.task.hidden = !taskMode;
  elements.check.hidden = !taskMode;
  elements.run.hidden = taskMode;
  elements.tests.hidden = !taskMode;
  elements["mode-task"].classList.toggle("active", taskMode);
  elements["mode-run"].classList.toggle("active", !taskMode);
}

elements.run.addEventListener("click", run);
elements.check.addEventListener("click", check);
elements.stop.addEventListener("click", () => {
  PascalABC.stop();
  setBusy(false, "Остановлено");
});
elements["mode-run"].addEventListener("click", () => selectMode(false));
elements["mode-task"].addEventListener("click", () => selectMode(true));
elements["load-graphics"].addEventListener("click", () => {
  selectMode(false);
  lightPTAssignment = null;
  elements.code.value = graphicsExample;
  elements.input.value = "";
  elements.status.textContent = "Пример GraphWPF загружен — нажмите Run";
  elements.code.focus();
});
elements["load-plotwpf"].addEventListener("click", () => {
  selectMode(false);
  lightPTAssignment = null;
  elements.code.value = plotWPFExample;
  elements.input.value = "";
  elements.status.textContent = "Пример PlotWPF загружен — нажмите Run";
  elements.code.focus();
});
elements["load-graphics3d"].addEventListener("click", () => {
  selectMode(false);
  lightPTAssignment = null;
  elements.code.value = graphics3DExample;
  elements.input.value = "";
  elements.status.textContent = "Пример Graph3D загружен — нажмите Run";
  elements.code.focus();
});
elements["load-lightpt"].addEventListener("click", async () => {
  setBusy(true, "Загрузка программы и скрытого Tasks.pas…");
  try {
    const [program, tasks] = await Promise.all([
      fetch("../examples/lightpt/Program.pas").then(response => response.text()),
      fetch("../examples/lightpt/Tasks.pas").then(response => response.text())
    ]);
    selectMode(false);
    elements.code.value = program;
    elements.input.value = "";
    lightPTAssignment = { tasks, taskName: "CountDivisibleByFour" };
    elements.status.textContent = "Программа загружена; скрытый Tasks.pas подключится автоматически";
    elements.code.focus();
  } catch (error) {
    elements.output.textContent = String(error);
    elements.status.textContent = "Не удалось загрузить пример LightPT";
  } finally {
    setBusy(false, elements.status.textContent);
  }
});
elements.code.addEventListener("keydown", event => {
  if (event.key === "Enter" && (event.ctrlKey || event.metaKey)) {
    event.preventDefault();
    elements.run.hidden ? check() : run();
  }
});

PascalABC.attachCanvas(elements["graphics-canvas"], {
  onOpen(details) {
    elements.graphics.hidden = false;
    elements["graphics-title"].textContent = details.title || "Графика";
    elements["graphics-renderer"].textContent = details.renderer === "webgl2" ? "WebGL 2 · мышь: вращение и масштаб" : "Canvas 2D";
  },
  onTitle(title) {
    elements["graphics-title"].textContent = title || "Графика";
  }
});

try {
  await PascalABC.init();
  elements.version.textContent = `PascalABC.NET ${PascalABC.version} · browser WASM`;
  setBusy(false, "Готово");
} catch (error) {
  elements.version.textContent = "runtime не загрузился";
  elements.output.textContent = String(error);
}
