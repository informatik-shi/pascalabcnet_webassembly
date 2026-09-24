# Графика в PascalABC.Web

## Почему WPF нельзя перенести напрямую

Оригинальный `GraphWPF.pas` публикует типы `System.Windows`, `System.Windows.Media`, `System.Windows.Shapes` и использует WPF dispatcher/drawing context. Оригинальный `Graph3D.pas` дополнительно зависит от `System.Windows.Media.Media3D` и `HelixToolkit.Wpf`. Эти сборки входят в Windows Desktop, отсутствуют в browser WASM и концептуально не могут рисовать в DOM.

PascalABC.Web поэтому предоставляет browser compatibility units с теми же именами. Это не подмена компилятора: исходный код ученика по-прежнему проходит оригинальные parser, semantic analyzer и IL generator PascalABC.NET. Заменяется только платформенный graphics backend.

## Реализованный путь GraphWPF и Graph3D

```text
program.pas (`uses GraphWPF`)
  → официальный PascalABC.NET compiler
  → browser GraphWPF.pcu
  → PascalABC.Web.Graphics managed bridge
  → JS interop внутри Worker
  → typed graphics message
  → BrowserGraphicsRenderer на main thread
  → HTML Canvas 2D или WebGL 2
```

Student assembly не получает DOM, `postMessage`, `fetch` или JavaScript global scope. Единственная доступная поверхность — типизированные методы graphics bridge. Протокол версионирован полем `protocol`; команда также содержит `executionId`, поэтому renderer различает последовательные запуски.

GraphWPF поддерживает:

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

Graph3D MVP поддерживает:

- `P3D`, `V3D`, `Sz3D`, базовые материалы и палитру `Colors`;
- `Sphere`, `Cube`, `Box`, `Cylinder`, `Cone`, `TruncatedCone`;
- `MoveTo/MoveBy`, осевые перемещения, `Scale/ScaleX/Y/Z`, `Rotate`, изменение цвета и удаление объекта;
- `View3D` (сетка, оси, фон, заголовок), `Window.SetSize` и базовую `Camera`;
- depth buffer, перспективную камеру, Lambert-освещение и генерируемые в браузере меши;
- orbit camera: перетаскивание мышью вращает сцену, колесо меняет расстояние.

При переключении между GraphWPF и Graph3D renderer заменяет backing canvas, потому что браузер не позволяет одному canvas одновременно иметь контексты `2d` и `webgl2`. Новый элемент сохраняет id, классы и обработчики верхнего уровня API.

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

## Следующие этапы Graph3D

`Graph3D` использует тот же элемент `<canvas>`, но WebGL 2 вместо Canvas 2D. Обычная 2D-проекция не сохранила бы семантику исходного модуля.

План переноса:

1. Дополнительные примитивы: `Prism/Pyramid`, плоскости, линии, стрелки и составные объекты.
2. Orthographic projection, настраиваемые источники света и Phong/specular materials.
3. Анимации через `requestAnimationFrame`: Pascal передаёт параметры tween/trajectory, а не рисует каждый кадр через JS interop.
4. Двусторонние события и picking. Canvas events идут main thread → Worker → сохранённый Pascal delegate отдельной runtime-операцией с timeout.
5. Text billboards, textures, grouping/cloning и WebGL1 fallback. WPF serialization, произвольные Helix meshes и desktop file dialogs не входят в browser scope.

Такое разделение позволяет развивать 2D и 3D независимо, сохраняя один sandboxed transport и не включая тяжёлую WebGL-библиотеку в console-only загрузку.
