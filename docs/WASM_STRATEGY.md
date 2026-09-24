# Стратегия WebAssembly

## Рассмотренные варианты

| Вариант | Оценка |
|---|---|
| A. Compile ahead-of-time → IL → .NET WASM runtime | Подходит для заранее известных программ, но не для кода ученика, введённого после загрузки страницы. Native AOT также не поддерживает динамическую генерацию/загрузку произвольного IL как рабочую модель. |
| B. PascalABC.NET IR → собственный WASM backend | Технически возможно как многолетний отдельный backend, но дублирует сложную семантику CLR: объекты, generics, reflection, exceptions, RTL. Для MVP неоправданно и ухудшает совместимость. |
| C. Compiler и программа внутри .NET/WASM | Выбран. .NET 10 Mono interpreter поддерживает необходимый managed compiler, `PersistedAssemblyBuilder`, PE metadata и `Assembly.Load`. |
| D. Server compiler service | Не нужен для MVP. Может появиться как опциональный режим для слабых устройств или серверной проверки, сохраняя JS API. |

## Выбранная схема

```text
Browser page
  └─ pascalabc-web.js
      └─ module Web Worker
          ├─ .NET 10 Mono WebAssembly runtime
          ├─ официальный PascalABC.NET compiler
          ├─ PABCSystem/PABCExtensions PCU
          └─ generated managed PE → Assembly.Load → Main
```

Это вариант C. После публикации все вычисления выполняются client-side; Node.js, Python и compiler backend для обслуживания сайта не нужны.

## Почему Mono/WASM, а не Native AOT

PascalABC.NET генерирует типы и CIL во время выполнения, сохраняет новую assembly и затем загружает её. Native AOT рассчитан на закрытый набор кода и ограничивает dynamic code loading. Mono interpreter в browser runtime медленнее AOT, но сохраняет необходимые CLR-возможности. Эксперимент показал `RuntimeFeature.IsDynamicCodeSupported = true`, `IsDynamicCodeCompiled = false`: динамический IL исполняется интерпретатором, без JIT.

## Build-time и run-time

На build-машине:

1. применяется небольшой browser patch к зафиксированному upstream;
2. собирается официальный `pabcnetc` для .NET 10;
3. тем же компилятором пересобираются стандартные PCU;
4. staging tool формирует metadata/RTL manifest;
5. Blazor WebAssembly SDK публикует статический runtime.

В браузере:

1. `dotnet.js` загружает Worker runtime;
2. только при `init()` загружаются compiler metadata и PCU;
3. `run/check/compile` сериализуются внутри Worker;
4. timeout завершает Worker целиком, что гарантированно прерывает даже `while true`;
5. следующий вызов создаёт чистый Worker.

## Известные ограничения

- Первая загрузка велика: untrimmed compiler и metadata имеют приоритет совместимости над минимальным размером.
- Initial compile занимает секунды, а не миллисекунды; HTTP compression и immutable cache обязательны в production.
- Worker termination теряет compiler cache и требует повторной инициализации.
- Нельзя включать Native AOT или aggressive trimming без отдельного большого compatibility pass.
- GraphABC, FormsABC, debugger и IDE plugins не входят в MVP.
- PCU стандартной библиотеки пока создаются на build-машине: компиляция их исходников внутри Mono/WASM блокируется отсутствующим runtime API `CustomAttributeBuilder`.

## Почему fallback service сейчас отсутствует

Browser-only путь доказан реальным выполнением, поэтому добавление backend увеличило бы поверхность атаки и операционные расходы без необходимости. Публичный API не привязан к внутреннему transport, поэтому service adapter можно добавить позднее.
