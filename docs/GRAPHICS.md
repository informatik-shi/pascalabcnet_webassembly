# Графика в PascalABC.Web

## Почему WPF нельзя перенести напрямую

Оригинальный `GraphWPF.pas` публикует типы `System.Windows`, `System.Windows.Media`, `System.Windows.Shapes` и использует WPF dispatcher/drawing context. Оригинальный `Graph3D.pas` дополнительно зависит от `System.Windows.Media.Media3D` и `HelixToolkit.Wpf`. Эти сборки входят в Windows Desktop, отсутствуют в browser WASM и концептуально не могут рисовать в DOM.

PascalABC.Web поэтому предоставляет browser compatibility units с теми же именами. Это не подмена компилятора: исходный код ученика по-прежнему проходит оригинальные parser, semantic analyzer и IL generator PascalABC.NET. Заменяется только платформенный graphics backend.

## Реализованный путь GraphWPF

```text
program.pas (`uses GraphWPF`)
  → официальный PascalABC.NET compiler
  → browser GraphWPF.pcu
  → PascalABC.Web.Graphics managed bridge
  → JS interop внутри Worker
  → typed graphics message
  → CanvasGraphicsRenderer на main thread
  → HTML Canvas 2D
```

Student assembly не получает DOM, `postMessage`, `fetch` или JavaScript global scope. Единственная доступная поверхность — типизированные методы graphics bridge. Протокол версионирован полем `protocol`; команда также содержит `executionId`, поэтому renderer различает последовательные запуски.

Первый вертикальный срез поддерживает:

- `Window.SetSize`, `Window.Title`, `Window.Clear`, размеры и центр окна;
- `Colors`, `RGB`, `ARGB`, `RandomColor`;
- `Pen`, `Brush`, `Font` и основные настройки;
- линии и относительное перемещение пера;
- прямоугольники, окружности и эллипсы;
- дуги и секторы;
- polyline/polygon и стрелки;
- `TextOut`, выравнивание и поворот текста;
- стандартную и базовую математическую систему координат;
- HiDPI Canvas с адаптивным отображением в demo.

Пока не поддержаны pixel batches/images/video, сохранение файлов/clipboard, frame-based animation, мышь/клавиатура и WPF-specific drawing objects. `TextSize` сейчас использует предсказуемую метрическую оценку, потому что синхронный DOM measurement из Worker нарушил бы sandbox и модель выполнения.

## JavaScript API

```js
const renderer = PascalABC.attachCanvas(document.querySelector("canvas"), {
  onOpen: ({ width, height, title }) => {},
  onTitle: title => {}
});

await PascalABC.run(`
uses GraphWPF;
begin
  Window.SetSize(800, 500);
  Window.Clear(Colors.WhiteSmoke);
  Brush.Color := Colors.Gold;
  Circle(400, 250, 100);
end.
`);
```

Без `attachCanvas` программа остаётся безопасно исполнимой, но graphics messages игнорируются main thread.

## План Graph3D

`Graph3D` должен использовать тот же элемент `<canvas>`, но не Canvas 2D. Для глубины, камеры, освещения и мешей нужен WebGL2 renderer (с WebGL1 fallback). Обычная 2D-проекция на Canvas не сохранит семантику исходного модуля.

План переноса:

1. Browser unit `Graph3D.pas` с совместимыми `Point3D`, `Vector3D`, `Material`, `Camera`, `View3D` и объектными handle-классами.
2. Scene protocol: `create`, `transform`, `material`, `visibility`, `remove`, camera/light commands. Каждый объект получает стабильный числовой id.
3. WebGL scene graph и mesh generators для `Sphere`, `Cube/Box`, `Cylinder/Cone`, `Prism/Pyramid`, линий и координатных осей.
4. Orbit camera, perspective/orthographic projection, ambient/directional/point light и базовый Lambert/Phong material.
5. Анимации исполняются renderer’ом через `requestAnimationFrame`; Pascal передаёт параметры tween/trajectory, а не рисует каждый кадр через JS interop.
6. Двусторонние события. Canvas events идут main thread → Worker → сохранённый Pascal delegate отдельной runtime-операцией. Каждый callback получает собственный timeout.
7. Поздние функции: text billboards, textures, picking, grouping/cloning. WPF serialization, произвольные Helix meshes и desktop file dialogs не входят в начальный scope.

Такое разделение позволяет развивать 2D и 3D независимо, сохраняя один sandboxed transport и не включая тяжёлую WebGL-библиотеку в console-only загрузку.
