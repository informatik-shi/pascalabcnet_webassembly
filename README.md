# PascalABC.Web

PascalABC.Web запускает **официальный PascalABC.NET compiler** и скомпилированную им программу непосредственно в браузере. Это не упрощённый интерпретатор и не FreePascal: official frontend строит AST и semantic tree, затем `NETGenerator` создаёт managed PE/CIL, который загружает .NET 10 Mono WebAssembly runtime.

Первый вертикальный сценарий подтверждён в Chrome/Edge: stdin `20\n22\n` даёт stdout `42\n`, `check()` прогоняет несколько тестов после одной компиляции, а бесконечный цикл завершается уничтожением Worker без блокировки UI.

## Быстрый старт

Требования для сборки: Git, .NET 10 SDK с workload `wasm-tools`, PowerShell 7+ (Windows) или Bash (Linux/macOS), Node.js только для локального static server.

```powershell
git clone --recurse-submodules https://github.com/informatik-shi/pascalabcnet_webassembly.git
cd pascalabcnet_webassembly
dotnet workload install wasm-tools
npm run build
npm run serve
```

Откройте `http://127.0.0.1:8080/demo/`. После build обслуживаются только статические файлы; на production server Node.js/.NET/backend не нужны.

Linux/macOS или Git Bash: не запускайте `build.ps1` как Bash-скрипт. Универсальная команда `npm run build` сама выберет `build.sh` на Unix и PowerShell на Windows:

```bash
git clone --recurse-submodules https://github.com/informatik-shi/pascalabcnet_webassembly.git
cd pascalabcnet_webassembly
dotnet workload install wasm-tools
npm run build
npm run serve
```

Если `npm run serve` уже запускается, вы, вероятно, уже находитесь в корне репозитория и повторный `cd pascalabcnet_webassembly` не нужен. Если `dotnet: command not found`, сначала установите .NET 10 SDK и откройте новый terminal; одной установки Node.js недостаточно.

## API

```js
import { PascalABC } from "./dist/pascalabc-web.js";

await PascalABC.init();

const result = await PascalABC.run(`
begin
  var a := ReadInteger;
  var b := ReadInteger;
  Println(a + b);
end.
`, {
  stdin: "20\n22\n",
  timeout: 3000
});

console.log(result.stdout); // 42\n
```

Доступны `init`, `compile`, `run`, `check`, `stop` и свойство `version`. Подробности: [docs/API.md](docs/API.md).

## Проверка решения

```js
const result = await PascalABC.check(studentCode, [
  { input: "2\n3\n", expected: "5\n" },
  { input: "10\n20\n", expected: "30\n" }
], {
  normalizeNewlines: true,
  trimTrailingWhitespace: true,
  ignoreTrailingNewline: false,
  timeout: 12000
});
```

## Структура

- `upstream/pascalabcnet` — официальный репозиторий, зафиксированный submodule;
- `patches/` — минимальная browser-host адаптация upstream;
- `src/PascalABC.Web.Runtime` — .NET/WASM host и JS export;
- `js/` — zero-dependency JS/TypeScript API и Worker;
- `demo/` — учебное demo Run/Stop/Проверить;
- `tests/programs` — 33 Pascal-программы;
- `tests/browser` — public API, full suite и timeout tests;
- `tools/AssetStager` — staging runtime metadata и PCU;
- `docs/` — исследование архитектуры, стратегия, безопасность и совместимость.

## Проверки в браузере

После `npm run serve`:

- `/tests/browser/smoke.html` — `version`, `run`, `check`;
- `/tests/browser/timeout.html` — неотзывчивый loop и heartbeat UI;
- `/tests/browser/suite.html` — все 33 программы, включая error/timeout cases.

Зафиксированный прогон и измерения: [docs/TEST_RESULTS.md](docs/TEST_RESULTS.md).

Первая загрузка и первая компиляция заметно тяжелее последующих. Настройте Brotli и immutable caching для fingerprinted `_framework` assets; правила приведены в [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md), фактические размеры — в [docs/SIZE_REPORT.md](docs/SIZE_REPORT.md).

## Ограничения MVP

Поддерживаются учебные console programs. GraphABC, FormsABC, desktop debugger/IDE plugins и доступ к пользовательской файловой системе не поддерживаются. Worker — важная граница отзывчивости, но не OS sandbox; для недоверенного кода используйте отдельный origin. См. [docs/SECURITY.md](docs/SECURITY.md) и [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md).

## Лицензии

Собственный glue-код PascalABC.Web распространяется по MIT. PascalABC.NET — GNU LGPL v3 с upstream clarifications/exceptions; полный текст включается в `dist/licenses/PascalABC.NET-LICENSE.txt`. См. [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

Пакет подготовлен к `npm pack`, но в npm автоматически не публикуется (`private: true`). Перед публикацией нужно отдельно проверить имя, provenance и лицензионный состав distribution.
