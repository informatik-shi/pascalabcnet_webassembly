# Размер сборки

Измерение Release build от 2026-09-24 (`net10.0`, trimming отключён ради совместимости):

| Артефакт | Raw | Brotli |
|---|---:|---:|
| `pascalabc-web.js` | 5 782 B | — |
| `pascalabc-worker.js` | 1 773 B | — |
| `dotnet.native.*.wasm` | 3 001 422 B | 976 255 B |
| весь `_framework` | 33 171 215 B | 10 499 289 B precompressed variants |
| `pabc-assets` | 47 482 760 B | 15 689 662 B precompressed variants |
| `dist` raw + Brotli + metadata/licenses | 106 861 540 B | — |

При server-side выборе существующего `.br` для каждого логического файла расчётная передача чистому браузерному cache составляет **28 815 841 B (≈27,5 MiB)**. Browser cache делает следующие открытия значительно дешевле.

`npm pack --dry-run`:

- tarball: 59 016 921 B;
- unpacked: 106 869 322 B;
- entries: 612.

В `dist` намеренно оставлены raw fallback и Brotli, но удалены дублирующие gzip-копии. Development server выполняет content negotiation по `Accept-Encoding: br`.

Главная причина размера — не JS glue, а untrimmed .NET runtime, compiler graph и отдельный комплект reference metadata (`System.Private.CoreLib.dll` 16 033 576 B raw, `System.Private.Xml.dll` 7 788 328 B raw). Эти metadata нужны compiler resolver и не равны runtime assemblies, которые выполняются Mono.

Следующая безопасная оптимизация — доказательно уменьшить набор reference metadata и ICU/runtime assemblies на основании расширенного compatibility suite. Включать global trimming сейчас нельзя: PascalABC.NET широко использует reflection и динамически созданные types.
