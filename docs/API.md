# JavaScript API

## Подключение

```js
import { PascalABC } from "./dist/pascalabc-web.js";

await PascalABC.init();
console.log(PascalABC.version);
```

`init()` создаёт Worker, загружает .NET/WASM и compiler assets. Первый вызов `compile`, `run` или `check` вызывает `init` автоматически. Для нестандартного layout можно передать:

```js
await PascalABC.init({
  workerUrl: "/pabc/pascalabc-worker.js",
  baseUrl: "/pabc/",
  initTimeout: 180_000
});
```

`baseUrl` должен содержать `_framework/` и `pabc-assets/`. Страницу нельзя открывать через `file://`; нужен обычный HTTP(S) server.

## Выполнение

```js
const result = await PascalABC.run(`
begin
  var a := ReadInteger;
  var b := ReadInteger;
  Println(a + b);
end.
`, {
  stdin: "20\n22\n",
  timeout: 3000,
  compileTimeout: 30000
});
```

Обычный результат:

```js
{
  success: true,
  stdout: "42\n",
  stderr: "",
  exitCode: 0,
  compileTime: 3592.6,
  executionTime: 5.1,
  diagnostics: [],
  artifactId: "pabc-000001",
  assemblyBytes: 89088
}
```

`timeout` ограничивает выполнение уже скомпилированного PE; `compileTimeout` отдельно ограничивает frontend/backend (default 30 секунд). При любом timeout Worker уничтожается, возвращается `{ success: false, timedOut: true, exitCode: 124, ... }`. Следующий вызов создаст новый runtime. `PascalABC.stop()` позволяет сделать то же вручную.

## Только компиляция

```js
const result = await PascalABC.compile(code, { timeout: 3000 });
```

Успешный результат содержит `artifactId` и `assemblyBytes`. Сами PE bytes намеренно не передаются в main thread MVP.

Compiler errors — оригинальные PascalABC.NET diagnostics:

```js
{
  success: false,
  exitCode: 1,
  diagnostics: [{
    line: 3,
    column: 12,
    severity: "error",
    code: "UnexpectedToken",
    message: "..."
  }]
}
```

## Проверка задания

```js
const result = await PascalABC.check(code, [
  { input: "2\n3\n", expected: "5\n" },
  { input: "10\n20\n", expected: "30\n" }
], {
  timeout: 12000,
  trimTrailingWhitespace: true,
  normalizeNewlines: true,
  ignoreTrailingNewline: false
});
```

Программа компилируется один раз. Для каждого теста PE заново загружается и entry point получает новый stdin/stdout:

```js
{
  success: true,
  passed: 2,
  failed: 0,
  tests: [{
    input: "2\n3\n",
    expected: "5\n",
    actual: "5\n",
    stderr: "",
    exitCode: 0,
    passed: true
  }],
  compileTime: 3275.1,
  diagnostics: []
}
```

`trimTrailingWhitespace` удаляет пробелы справа на каждой строке; `normalizeNewlines` приводит CRLF/CR к LF; `ignoreTrailingNewline` игнорирует конечные переводы строк. Default: `true`, `true`, `false`.

Полные TypeScript declarations находятся в `js/pascalabc-web.d.ts`.
