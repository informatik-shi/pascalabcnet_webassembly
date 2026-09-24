# Модель безопасности

## Короткий вывод

Код ученика выполняется не в основном UI, а в отдельном module Worker и отдельном .NET/WASM runtime. Это защищает отзывчивость страницы и убирает обычный прямой доступ к DOM, cookies, `localStorage` и window globals. Таймаут уничтожает Worker целиком.

Worker/WASM **не является криптографической или OS-процессной песочницей**. Размещайте playground на отдельном origin без ценных cookies и секретов. Не используйте его как единственный барьер для враждебного кода высокой ценности.

## Реализованные границы

- Student entry point выполняется только внутри Worker.
- DOM/window/cookies/localStorage в Worker отсутствуют.
- Файловые операции видят только эфемерную in-memory VFS .NET; пользовательская файловая система не монтируется.
- После загрузки compiler assets Worker заменяет `fetch` на deny-функцию и отключает доступные `WebSocket`, `EventSource`, `XMLHttpRequest` globals.
- Demo CSP разрешает scripts, workers и connections только с собственного origin.
- `timeout` вызывает `Worker.terminate()`. Это единственный надёжный способ остановить некооперативный managed loop.
- Временные source/PE/PDB/runtimeconfig удаляются после компиляции; сохранено не более 16 PE artifacts в памяти.
- Операции сериализуются, чтобы глобальное состояние upstream compiler не использовалось конкурентно.

## Остаточные риски

1. .NET runtime и компилятор работают в одном Worker. Reflection-код может исследовать уже загруженные managed assemblies и влиять на состояние этого Worker.
2. Browser implementation или .NET runtime может сохранить внутреннюю ссылку на network primitive до JavaScript lockdown. CSP и отдельный origin остаются обязательной второй границей.
3. Same-origin fetch до lockdown нужен для загрузки runtime/assets. Не помещайте секретные same-origin endpoints рядом с playground.
4. Большой/патологический source может расходовать CPU и память во время компиляции. Общий request timeout тоже завершает Worker, но вкладка может испытывать memory pressure до termination.
5. Side channels, browser/runtime vulnerabilities и denial of service всей вкладки не исключены.
6. Worker termination не даёт транзакционных гарантий для будущих явно разрешённых внешних ресурсов.

## Рекомендуемое развёртывание

- Отдельный origin, например `play.example.edu`, без auth cookies и service worker основного приложения.
- CSP минимум: `default-src 'self'; script-src 'self'; worker-src 'self'; connect-src 'self'; object-src 'none'; base-uri 'none'`.
- HTTPS, `X-Content-Type-Options: nosniff`, корректные MIME для `.js` и `.wasm`.
- Не добавлять `unsafe-eval`, произвольные CDN origins или JS interop bindings в Worker.
- Если результаты влияют на оценки, повторять проверку на доверенном сервере. Client-side checker удобен для мгновенной обратной связи, но ученик контролирует свою вкладку и может подделать UI/result object.

## Что не является доступом к диску

Каталоги `/pabc/runtime`, `/pabc/Lib` и `/pabc/work` существуют только внутри памяти WASM Worker. Они не дают программе доступ к `C:\`, домашнему каталогу или File System Access API браузера.
