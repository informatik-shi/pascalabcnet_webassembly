# Проверенный результат

Дата: 2026-09-24. Browser: Chromium engine через реальную вкладку Codex in-app browser; сайт обслуживался `scripts/serve-static.mjs` по HTTP.

## Definition of Done

`demo/index.html`:

- runtime: PascalABC.NET `4.0.0.3869`, .NET 10 WebAssembly;
- source: два `ReadInteger`, затем `Println(a + b)`;
- stdin: `20\n22`;
- stdout в UI: `42`;
- измерение: compile 2 880 ms, execute 5 ms.

Режим задания того же demo: `3 из 3`, все строки тестов отмечены ✓.

## Public API smoke

- `PascalABC.run`: success, stdout `42\n`, exit code 0, generated PE 89 088 bytes;
- `PascalABC.check`: 2 passed, 0 failed, два разных stdin на одной компиляции;
- compiler version: `4.0.0.3869`.

## Full browser suite

`tests/browser/suite.html`: **33 passed, 0 failed**.

Проверены integer/real/boolean/string/char, arithmetic, if/case, for/while/repeat, static/dynamic arrays, procedures, functions/recursion, Math, Write/Writeln/Print/Println, Read/Readln/ReadInteger/ReadReal/ReadString, compile error, runtime error и infinite loop timeout.

Длинный suite также выявил и позволил исправить eviction bug после 16 artifacts; финальный результат получен после исправления FIFO.

## PlotWPF в браузере

`tests/browser/plotwpf.html`: **PASS**. Программа с двумя областями графика успешно скомпилирована и выполнена без diagnostics; Canvas 2D получил размер 760×420 и 3 604 цветных пикселя. Проверены две линии, маркеры `Diamond`, `Thickness`, `ChangeData` и фиксированный `PlotRect`.

## Timeout и UI

Для `while true` при `timeout: 500`:

```text
timedOut: true
exitCode: 124
compileTime: 2971.3 ms
executionTime: 500 ms
wall elapsed including compile: 3560.6 ms
mainThreadTicks: 513
uiResponsive: true
```

Compilation и execution имеют отдельные лимиты; Worker уничтожается на execution timeout.

## Build/package/HTTP

- `scripts/build.ps1 -SkipUpstreamBuild`: success;
- official standard library: 18 757 строк пересобраны;
- asset staging: 84 raw files, 47 812 194 bytes до publish compression;
- `npm pack --dry-run`: success;
- JS syntax checks: success;
- browser patch reverse-check и `git diff --check`: success;
- `Accept-Encoding: br` для `.wasm`: response `Content-Type: application/wasm`, `Content-Encoding: br`;
- raw fallback без `Accept-Encoding`: response `application/wasm` без content encoding.

NU1900 в build log — warning недоступности online NuGet vulnerability index в изолированном окружении; restore/build использовали уже доступные packages и завершились успешно.
