# Архитектура PascalABC.Web

## Основание исследования

PascalABC.Web использует официальный репозиторий [pascalabcnet/pascalabcnet](https://github.com/pascalabcnet/pascalabcnet) как git submodule. Исследованный и зафиксированный коммит: `394bc8eab4af6af8f4e840570eb15aebebe0da70` от 2026-09-23. Собственный parser или интерпретатор Pascal в проекте отсутствует.

Актуальный upstream уже содержит modern-ветку консольного компилятора для `net10.0`; старая IDE остаётся на .NET Framework/Windows. Поэтому переносить VisualPascalABC.NET в браузер не требуется: web-host ссылается только на проекты компилятора.

## Pipeline исходного компилятора

| Стадия | Проект и основные точки входа | Роль |
|---|---|---|
| CLI | `pabcnetc/ConsoleCompiler.cs`, `ConsoleCompiler.Main` | Разбор аргументов и вызов ядра; в web-сборку не входит. |
| Оркестрация | `Compiler/Compiler.cs`, `Compiler.Compile` | Загружает язык, модули и PCU, запускает frontend, семантику и backend, собирает оригинальные errors/warnings. |
| Регистрация Pascal | `PascalABCLanguageInfo/PascalLanguageRegistration.cs`, `PascalABCLanguage.cs` | Связывает parser, syntax converters и semantic converter. В браузере вызывается явно вместо поиска plugin DLL на диске. |
| Lexer/parser | `Parsers/PascalABCParserNewSaushkin/Parser.cs`, сгенерированные `ABCPascalYacc.cs` и lexer-файлы | Строит оригинальное синтаксическое дерево PascalABC.NET. |
| AST | проект `SyntaxTree` | Типы узлов исходного синтаксического дерева. |
| AST transforms | `SyntaxTreeConverters`, `PascalABCLanguageInfo/Frontend/Converters` | Нормализация и раскрытие расширенного синтаксиса. |
| Семантика | `Compiler/SyntaxTreeToSemanticTreeConverter.cs`, `TreeConverter/TreeConversion/syntax_tree_visitor.cs` | Разрешение имён и перегрузок, проверка типов, построение semantic tree. |
| Semantic tree | проект `SemanticTree` | Контракты и узлы типизированного дерева. |
| IL backend | `NETGenerator/NETGenerator.cs` | Генерирует .NET metadata и IL. Modern-ветка использует `PersistedAssemblyBuilder.GenerateMetadata` и `ManagedPEBuilder`. |
| RTL | `bin/Lib/PABCSystem.pas`, `PABCExtensions.pas`, соответствующие `.pcu` | `Println`, `ReadInteger`, строки, массивы и другие учебные операции. |

Web-host вызывает `Compiler.Compile(CompilerOptions)` непосредственно. Результат — настоящий managed PE (`.exe`) с CIL, metadata и entry point; это не JavaScript-транспиляция и не отдельный Pascal runtime.

## Что относится только к IDE

`VisualPascalABCNET`, `VisualPlugins`, WinForms/WPF editor, debugger UI, designer, help и installer-проекты не нужны для консольных программ. Они зависят от Windows, .NET Framework, GAC, WinForms/WPF и нередко от динамического поиска плагинов. Они намеренно исключены из web-графа проектов.

Web-проект ссылается на `Compiler` и `PascalABCLanguageInfo`. Через их project references подключаются parser, syntax/semantic tree, TreeConverter, NETGenerator и необходимые utility-проекты.

## Зависимости, мешавшие браузеру

1. `Assembly.Location` и `ManifestModule.FullyQualifiedName` пусты у browser-hosted assemblies. `NetCoreSystemReferences` ранее пытался читать системные DLL именно из физического runtime-каталога.
2. `Compiler` и `SemanticTreeConvertersController` сканировали каталоги `*LanguageInfo.dll`/`*Conversion.dll`; в WASM нет обычного каталога загруженных сборок.
3. IL backend должен сохранить PE на диск. В браузере это работает через виртуальную in-memory файловую систему .NET.
4. Стандартный `PABCSystem` использовал `Console.In/Out`. В Worker нет интерактивной консоли.
5. Пересборка самого `PABCSystem.pas` внутри Mono/WASM упирается в не реализованный там путь `CustomAttributeBuilder` (`MethodBase.GetParametersCount`). Поэтому PCU собираются тем же официальным net10-компилятором на build-машине, а не в браузере.

Минимальный patch в `patches/pascalabcnet-browser.patch`:

- позволяет host задать каталог runtime metadata в WASM VFS;
- отключает необязательное сканирование несуществующих plugin-каталогов;
- делает поиск стандартных assembly безопасным без Windows/GAC;
- добавляет host-provided `TextReader`/`TextWriter` в `PABCSystem`, сохраняя обычный `Console` fallback на desktop.

## Что загружается в браузер

При `PascalABC.init()` Worker запускает .NET 10 Mono WebAssembly runtime. Затем `pabc-assets/manifest.json` лениво загружает относительно boot runtime:

- metadata-сборки .NET, которые читает `NetCoreSystemReferences`;
- `PABCSystem.pcu` и `PABCExtensions.pcu`;
- исходники этих модулей для корректных ссылок/диагностик.

Файлы помещаются в `/pabc/runtime` и `/pabc/Lib` виртуальной файловой системы Worker. Пользовательская программа компилируется в `/pabc/work`, PE читается в `byte[]`, временные файлы удаляются, затем PE загружается через `Assembly.Load` и вызывается его реальный entry point.

## Подтверждённый вертикальный сценарий

В Chrome/Edge-совместимом браузере проверено:

1. .NET/WASM сообщает `PersistedAssemblyBuilder: true`, `Assembly.Load: true`.
2. Официальный компилятор версии `4.0.0.3869` компилирует программу с `ReadInteger`/`Println`.
3. Создаётся managed PE размером 89 088 байт.
4. Entry point `program.Program.Main` выполняется внутри того же Worker.
5. Для stdin `20\n22\n` stdout равен `42\n`.

Это доказывает весь путь source → parser/AST → semantic analysis → .NET IL → загрузка и выполнение в browser WASM runtime.
