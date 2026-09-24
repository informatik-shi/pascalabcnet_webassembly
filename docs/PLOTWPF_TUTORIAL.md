# PlotWPF в браузере: пошаговый тьюториал

`PlotWPF` строит учебные графики прямо в браузере на HTML Canvas 2D. Код программы остаётся обычным PascalABC.NET-кодом: достаточно написать `uses PlotWPF`, создавать графики и запускать программу. Работать с JavaScript или DOM ученику не нужно.

## 1. Первый график функции

Откройте demo, нажмите **Пример PlotWPF**, затем **Run**. Минимальная программа выглядит так:

```pascal
uses PlotWPF;

begin
  var graph := new LineGraphWPF(-Pi, Pi, x -> Sin(x));
  graph.Title := 'y = sin(x)';
end.
```

Конструктор получает левую и правую границы и функцию `real -> real`. `PlotWPF` выбирает 200 точек, вычисляет значения и автоматически подбирает диапазоны обеих осей.

## 2. Цвет и толщина линии

Цвет можно передать в конструктор, а свойства первой серии доступны как `Graph[0]`:

```pascal
uses PlotWPF;

begin
  var graph := new LineGraphWPF(-2 * Pi, 2 * Pi,
    x -> Sin(x), Colors.RoyalBlue);
  graph.Title := 'Синус';
  graph.Graph[0].Thickness := 3;
end.
```

Поддерживаются цвета `Colors`, функции `RGB(r, g, b)`, `ARGB(a, r, g, b)`, `GrayColor` и `RandomColor`.

## 3. Несколько линий на одном поле

Метод `AddLineGraph` добавляет ещё одну серию в существующий график:

```pascal
uses PlotWPF;

begin
  var graph := new LineGraphWPF(-Pi, Pi,
    x -> Sin(x), Colors.RoyalBlue);
  graph.AddLineGraph(-Pi, Pi, x -> Cos(x), Colors.Coral);
  graph.Graph[0].Thickness := 3;
  graph.Graph[1].Thickness := 2;
  graph.Title := 'Синус и косинус';
end.
```

Нумерация серий начинается с нуля и совпадает с порядком добавления.

## 4. График по готовым данным

Вместо формулы можно передать две последовательности одинаковой длины — координаты `x` и `y`:

```pascal
uses PlotWPF;

begin
  var xx := Arr(1.0, 2.0, 3.0, 4.0, 5.0);
  var yy := Arr(2.0, 5.0, 3.0, 7.0, 4.0);

  var graph := new LineGraphWPF(xx, yy, Colors.Green);
  graph.Title := 'Результаты измерений';
end.
```

Если длины последовательностей различаются, используются пары до конца более короткой последовательности. Значения `NaN` и бесконечности пропускаются.

## 5. Точки и формы маркеров

`MarkerGraphWPF` показывает отдельные наблюдения. Последние два аргумента задают форму и размер маркера:

```pascal
uses PlotWPF;

begin
  var xx := Arr(1.0, 2.0, 3.0, 4.0, 5.0);
  var yy := Arr(2.0, 5.0, 3.0, 7.0, 4.0);

  var graph := new MarkerGraphWPF(xx, yy,
    Colors.Coral, MarkerType.Diamond, 12);
  graph.Title := 'Эксперимент';
end.
```

Доступны `Circle`, `Box`, `Triangle`, `Diamond` и `Cross`. Форму уже созданной серии можно изменить:

```pascal
graph.Graph[0].MarkerType := MarkerType.Cross;
```

Линии и маркеры можно совмещать через `AddLineGraph` и `AddMarkerGraph`.

## 6. Несколько графиков в сетке

`GridWPF` задаёт число строк, столбцов и промежуток между областями. Созданные после него графики занимают ячейки слева направо, затем сверху вниз:

```pascal
uses PlotWPF;

begin
  var grid := new GridWPF(2, 2, 10);

  var g1 := new LineGraphWPF(-Pi, Pi, x -> Sin(x), Colors.RoyalBlue);
  g1.Title := 'sin(x)';

  var g2 := new LineGraphWPF(-Pi, Pi, x -> Cos(x), Colors.Coral);
  g2.Title := 'cos(x)';

  var g3 := new LineGraphWPF(-2.0, 2.0, x -> x * x, Colors.Green);
  g3.Title := 'x²';

  var g4 := new LineGraphWPF(-2.0, 2.0, x -> x * x * x, Colors.Purple);
  g4.Title := 'x³';
end.
```

Размер Canvas подбирается автоматически: не менее 640×420 пикселей и примерно 380×280 на ячейку.

## 7. Фиксированный диапазон осей

По умолчанию диапазон вычисляется по данным с небольшими полями. Чтобы сравнивать несколько графиков в одном масштабе, задайте `PlotRect`:

```pascal
var graph := new LineGraphWPF(-5.0, 5.0, x -> x * x);
graph.PlotRect := Rect(-5, -2, 10, 30);
```

Здесь `Rect(x, y, width, height)` означает диапазон `x..x+width` по горизонтали и `y..y+height` по вертикали.

## 8. Замена данных

`ChangeData` меняет данные выбранной серии и сразу перерисовывает весь Canvas:

```pascal
uses PlotWPF;

begin
  var graph := new LineGraphWPF(-Pi, Pi, x -> Sin(x), Colors.RoyalBlue);
  graph.Graph[0].ChangeData(-Pi, Pi, x -> Sin(2 * x));

  var xx := Arr(0.0, 1.0, 2.0, 3.0);
  var yy := Arr(1.0, 4.0, 2.0, 6.0);
  graph.Graph[0].ChangeData(xx, yy);
end.
```

В browser-версии это синхронная замена изображения. Непрерывная анимация и обработчики мыши пока не входят в поддерживаемое подмножество.

## 9. Полный пример

```pascal
uses PlotWPF;

begin
  var grid := new GridWPF(1, 2, 10);

  var waves := new LineGraphWPF(-Pi, Pi,
    x -> Sin(x), Colors.RoyalBlue);
  waves.Title := 'Синус и косинус';
  waves.Graph[0].Thickness := 3;
  waves.AddLineGraph(-Pi, Pi, x -> Cos(x), Colors.Coral);

  var xx := Arr(1.0, 2.0, 3.0, 4.0, 5.0);
  var yy := Arr(2.0, 5.0, 3.0, 7.0, 4.0);
  var points := new MarkerGraphWPF(xx, yy,
    Colors.Green, MarkerType.Diamond, 10);
  points.Title := 'Наблюдения';
  points.AddLineGraph(xx, yy, Colors.LightGreen);
end.
```

## Что поддерживается

Browser-модуль сохраняет основной учебный API оригинального `PlotWPF`: `GridWPF`, `LineGraphWPF`, `MarkerGraphWPF`, несколько серий, заголовки, `PlotRect`, стили и `ChangeData`. Отрисовка выполняется через browser-версию `GraphWPF`, поэтому программа работает внутри Worker и не получает прямого доступа к странице.

WPF-контролы, произвольные объекты `InteractiveDataDisplay`, интерактивные легенды, zoom/pan и экспорт изображения пока не реализованы. Для обычных учебных графиков функций и наборов данных дополнительный код на стороне сайта не требуется — достаточно один раз подключить Canvas через JavaScript API `PascalABC.attachCanvas()`.
