# Совместимость MVP

Статус ✓ означает, что соответствующая программа есть в `tests/programs`, компилируется официальным frontend и входит в browser suite. “Ограниченно” означает сознательно суженную browser-модель.

| Возможность | Desktop PascalABC.NET | PascalABC.Web | Тест/замечание |
|---|---:|---:|---|
| `begin/end` | ✓ | ✓ | `01_hello.pas` |
| `integer`, арифметика, `div/mod` | ✓ | ✓ | `03_integer_arithmetic.pas` |
| `real` | ✓ | ✓ | `04_real.pas` |
| `boolean` | ✓ | ✓ | `05_boolean.pas` |
| `string` | ✓ | ✓ | `06_string.pas` |
| `char` | ✓ | ✓ | `07_char.pas` |
| `if` | ✓ | ✓ | `08_if.pas` |
| `case` | ✓ | ✓ | `09_case.pas` |
| `for` | ✓ | ✓ | `10_for.pas` |
| `while` | ✓ | ✓ | `11_while.pas` |
| `repeat` | ✓ | ✓ | `12_repeat.pas` |
| Статические массивы | ✓ | ✓ | `13_static_array.pas` |
| Динамические массивы | ✓ | ✓ | `14_dynamic_array.pas` |
| Процедуры | ✓ | ✓ | `15_procedure.pas` |
| Функции/рекурсия | ✓ | ✓ | `16_function.pas`, `30_recursive_function.pas` |
| Math (`Sqrt`, `Power`) | ✓ | ✓ | `17_math.pas` |
| `Write`, `Writeln` | ✓ | ✓ | `18_write.pas`, `19_writeln.pas` |
| `Print`, `Println` | ✓ | ✓ | `20_print.pas`, `21_println.pas` |
| `Read`, `Readln` | ✓ | ✓ | `22_read.pas`, `23_readln.pas` |
| `ReadInteger`, `ReadReal`, `ReadString` | ✓ | ✓ | `24`–`26` |
| Compile diagnostics | ✓ | ✓ | `31_compile_error.pas` |
| Runtime diagnostics | ✓ | ✓ | `32_runtime_error.pas` |
| Infinite-loop timeout | внешняя остановка | ✓ | `33_infinite_loop.pas`, Worker termination |
| LINQ/extension `Sum` | ✓ | ✓ | `13_static_array.pas`, `14_dynamic_array.pas` |
| Console stdin/stdout | ✓ | ✓ | Host-provided readers/writers |
| Файловый I/O | ✓ | ограниченно | Только эфемерная VFS Worker, без файлов пользователя |
| Network APIs | ✓ | ✗ | Блокируются после runtime initialization |
| Threads/tasks | ✓ | ограниченно | Нет гарантии для произвольных threading сценариев; не заявлено MVP |
| Reflection | ✓ | ограниченно | Только загруженные managed assemblies Worker |
| GraphABC | ✓ | ✗ | Windows/UI dependency |
| FormsABC/WinForms/WPF | ✓ | ✗ | Windows/UI dependency |
| Debugger и IDE plugins | ✓ | ✗ | Не входят в compiler host |

Browser suite: `tests/browser/suite.html`. Smoke API: `tests/browser/smoke.html`. Изоляция/timeout: `tests/browser/timeout.html`.
