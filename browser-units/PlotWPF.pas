// Browser compatibility implementation of the PascalABC.NET PlotWPF API.
// Charts are rendered with the browser GraphWPF unit on Canvas 2D.
unit PlotWPF;

interface

uses GraphWPF;

type
  GColor = GraphWPF.GColor;
  GRect = GraphWPF.GRect;
  Point = GraphWPF.Point;
  Colors = GraphWPF.Colors;

  MarkerType = (Circle, Box, Triangle, Diamond, Cross);
  MarkerTyp = MarkerType;

  BaseGraphWPF = class;
  GridWPF = class;

  PlotSeriesKind = (LineSeries, MarkerSeries);

  PlotSeries = class
  public
    Kind: PlotSeriesKind;
    XValues, YValues: array of real;
    Color: GColor;
    Thickness: real := 1.4;
    Marker: MarkerType := MarkerType.Circle;
    MarkerSize: real := 10;
  end;

  ChartGr = class
  private
    Owner: BaseGraphWPF;
    SeriesIndex: integer;
    function GetColor: GColor;
    procedure SetColor(value: GColor);
    function GetThickness: real;
    procedure SetThickness(value: real);
    function GetMarkerType: PlotWPF.MarkerType;
    procedure SetMarkerType(value: PlotWPF.MarkerType);
  public
    constructor(owner: BaseGraphWPF; seriesIndex: integer);
    procedure ChangeData(a, b: real; f: real -> real);
    procedure ChangeData(xx, yy: sequence of real);
    property Color: GColor read GetColor write SetColor;
    property Thickness: real read GetThickness write SetThickness;
    property MarkerType: PlotWPF.MarkerType read GetMarkerType write SetMarkerType;
  end;

  BaseGraphWPF = class
  private
    SeriesList := new List<PlotSeries>;
    CellIndex: integer;
    FTitle := '';
    FPlotRect: GRect;
    function GetGraph(index: integer): ChartGr;
    function GetTitle: string;
    procedure SetTitle(value: string);
    function GetPlotRect: GRect;
    procedure SetPlotRect(value: GRect);
  protected
    constructor Create;
    procedure ReplaceData(index: integer; xx, yy: sequence of real);
    function SeriesAt(index: integer): PlotSeries;
  public
    property Title: string read GetTitle write SetTitle;
    property PlotRect: GRect read GetPlotRect write SetPlotRect;
    property Graph[index: integer]: ChartGr read GetGraph;
    procedure AddLineGraph(xx, yy: sequence of real; color: GColor := -65536);
    procedure AddLineGraph(a, b: real; f: real -> real; color: GColor := -65536);
    procedure AddMarkerGraph(xx, yy: sequence of real; color: GColor := -16711681;
      MType: MarkerType := MarkerType.Circle; MarkerSize: real := 10);
    procedure AddMarkerGraph(xx, yy: sequence of real; MType: MarkerType);
    procedure AddMarkerGraph(xx, yy: sequence of real; MarkerSize: real);
  end;

  LineGraphWPF = class(BaseGraphWPF)
  public
    constructor(a, b: real; f: real -> real; color: GColor := -65536);
    constructor(xx, yy: sequence of real; color: GColor := -65536);
  end;

  MarkerGraphWPF = class(BaseGraphWPF)
  public
    constructor(xx, yy: sequence of real; color: GColor := -16711681;
      MType: MarkerType := MarkerType.Circle; MarkerSize: real := 10);
    constructor(xx, yy: sequence of real; MType: MarkerType);
    constructor(xx, yy: sequence of real; color: GColor; MarkerSize: real);
  end;

  GridWPF = class
  public
    Rows, Columns: integer;
    Gap: real;
    constructor(rows, columns: integer; gap: real := 8);
  end;

function RGB(r, g, b: byte): GColor;
function ARGB(a, r, g, b: byte): GColor;
function GrayColor(value: byte): GColor;
function RandomColor: GColor;
function EmptyColor: GColor;
function Pnt(x, y: real): Point;
function Rect(x, y, width, height: real): GRect;

implementation

var
  CurrentGrid: GridWPF;
  Charts := new List<BaseGraphWPF>;

procedure RedrawAll; forward;

function RGB(r, g, b: byte): GColor := GraphWPF.RGB(r, g, b);
function ARGB(a, r, g, b: byte): GColor := GraphWPF.ARGB(a, r, g, b);
function GrayColor(value: byte): GColor := GraphWPF.GrayColor(value);
function RandomColor: GColor := GraphWPF.RandomColor;
function EmptyColor: GColor := GraphWPF.EmptyColor;
function Pnt(x, y: real): Point := GraphWPF.Pnt(x, y);
function Rect(x, y, width, height: real): GRect := GraphWPF.Rect(x, y, width, height);

constructor GridWPF.Create(rows, columns: integer; gap: real);
begin
  Self.Rows := Max(1, rows);
  Self.Columns := Max(1, columns);
  Self.Gap := Max(0, gap);
  CurrentGrid := Self;
  Charts.Clear;
  GraphWPF.Window.Title := 'PlotWPF';
  GraphWPF.Window.SetSize(Max(640, Self.Columns * 380), Max(420, Self.Rows * 280));
  RedrawAll;
end;

constructor BaseGraphWPF.Create;
begin
  if CurrentGrid = nil then
    CurrentGrid := new GridWPF(1, 1, 8);
  CellIndex := Charts.Count;
  Charts.Add(Self);
end;

function BaseGraphWPF.SeriesAt(index: integer): PlotSeries;
begin
  if (index < 0) or (index >= SeriesList.Count) then
    raise new System.ArgumentOutOfRangeException('index');
  Result := SeriesList[index];
end;

procedure BaseGraphWPF.ReplaceData(index: integer; xx, yy: sequence of real);
begin
  var series := SeriesAt(index);
  series.XValues := xx.ToArray;
  series.YValues := yy.ToArray;
  RedrawAll;
end;

function BaseGraphWPF.GetGraph(index: integer): ChartGr := new ChartGr(Self, index);
function BaseGraphWPF.GetTitle: string := FTitle;
procedure BaseGraphWPF.SetTitle(value: string); begin FTitle := value; RedrawAll; end;
function BaseGraphWPF.GetPlotRect: GRect := FPlotRect;
procedure BaseGraphWPF.SetPlotRect(value: GRect); begin FPlotRect := value; RedrawAll; end;

procedure BaseGraphWPF.AddLineGraph(xx, yy: sequence of real; color: GColor);
begin
  var series := new PlotSeries;
  series.Kind := PlotSeriesKind.LineSeries;
  series.XValues := xx.ToArray;
  series.YValues := yy.ToArray;
  series.Color := color;
  SeriesList.Add(series);
  RedrawAll;
end;

procedure BaseGraphWPF.AddLineGraph(a, b: real; f: real -> real; color: GColor);
begin
  var xx := PartitionPoints(a, b, 200);
  AddLineGraph(xx, xx.Select(f), color);
end;

procedure BaseGraphWPF.AddMarkerGraph(xx, yy: sequence of real; color: GColor;
  MType: MarkerType; MarkerSize: real);
begin
  var series := new PlotSeries;
  series.Kind := PlotSeriesKind.MarkerSeries;
  series.XValues := xx.ToArray;
  series.YValues := yy.ToArray;
  series.Color := color;
  series.Marker := MType;
  series.MarkerSize := Max(1, MarkerSize);
  SeriesList.Add(series);
  RedrawAll;
end;

procedure BaseGraphWPF.AddMarkerGraph(xx, yy: sequence of real; MType: MarkerType) :=
  AddMarkerGraph(xx, yy, Colors.Cyan, MType, 10);
procedure BaseGraphWPF.AddMarkerGraph(xx, yy: sequence of real; MarkerSize: real) :=
  AddMarkerGraph(xx, yy, Colors.Cyan, MarkerType.Circle, MarkerSize);

constructor LineGraphWPF.Create(a, b: real; f: real -> real; color: GColor);
begin
  inherited Create;
  AddLineGraph(a, b, f, color);
end;

constructor LineGraphWPF.Create(xx, yy: sequence of real; color: GColor);
begin
  inherited Create;
  AddLineGraph(xx, yy, color);
end;

constructor MarkerGraphWPF.Create(xx, yy: sequence of real; color: GColor;
  MType: MarkerType; MarkerSize: real);
begin
  inherited Create;
  AddMarkerGraph(xx, yy, color, MType, MarkerSize);
end;

constructor MarkerGraphWPF.Create(xx, yy: sequence of real; MType: MarkerType);
begin
  inherited Create;
  AddMarkerGraph(xx, yy, Colors.Cyan, MType, 10);
end;

constructor MarkerGraphWPF.Create(xx, yy: sequence of real; color: GColor; MarkerSize: real);
begin
  inherited Create;
  AddMarkerGraph(xx, yy, color, MarkerType.Circle, MarkerSize);
end;

constructor ChartGr.Create(owner: BaseGraphWPF; seriesIndex: integer);
begin
  Self.Owner := owner;
  Self.SeriesIndex := seriesIndex;
  Self.Owner.SeriesAt(Self.SeriesIndex);
end;

procedure ChartGr.ChangeData(a, b: real; f: real -> real);
begin
  var xx := PartitionPoints(a, b, 200);
  ChangeData(xx, xx.Select(f));
end;

procedure ChartGr.ChangeData(xx, yy: sequence of real) := Owner.ReplaceData(SeriesIndex, xx, yy);
function ChartGr.GetColor: GColor := Owner.SeriesAt(SeriesIndex).Color;
procedure ChartGr.SetColor(value: GColor); begin Owner.SeriesAt(SeriesIndex).Color := value; RedrawAll; end;
function ChartGr.GetThickness: real := Owner.SeriesAt(SeriesIndex).Thickness;
procedure ChartGr.SetThickness(value: real); begin Owner.SeriesAt(SeriesIndex).Thickness := Max(0.1, value); RedrawAll; end;
function ChartGr.GetMarkerType: PlotWPF.MarkerType := Owner.SeriesAt(SeriesIndex).Marker;
procedure ChartGr.SetMarkerType(value: PlotWPF.MarkerType); begin Owner.SeriesAt(SeriesIndex).Marker := value; RedrawAll; end;

function IsFiniteValue(value: real): boolean :=
  not System.Double.IsNaN(value) and not System.Double.IsInfinity(value);

function TickText(value: real): string := (Round(value * 100) / 100).ToString;
function MapX(value, xmin, xmax, left, width: real): real :=
  left + (value - xmin) / (xmax - xmin) * width;
function MapY(value, ymin, ymax, top, height: real): real :=
  top + height - (value - ymin) / (ymax - ymin) * height;

procedure DrawMarker(x, y, size: real; color: GColor; marker: MarkerType; thickness: real);
begin
  var radius := size / 2;
  var oldWidth := GraphWPF.Pen.Width;
  GraphWPF.Pen.Width := thickness;
  case marker of
    MarkerType.Circle: GraphWPF.FillCircle(x, y, radius, color);
    MarkerType.Box: GraphWPF.FillRectangle(x - radius, y - radius, size, size, color);
    MarkerType.Triangle: GraphWPF.FillPolygon(Arr(
      GraphWPF.Pnt(x, y - radius), GraphWPF.Pnt(x + radius, y + radius),
      GraphWPF.Pnt(x - radius, y + radius)), color);
    MarkerType.Diamond: GraphWPF.FillPolygon(Arr(
      GraphWPF.Pnt(x, y - radius), GraphWPF.Pnt(x + radius, y),
      GraphWPF.Pnt(x, y + radius), GraphWPF.Pnt(x - radius, y)), color);
    MarkerType.Cross:
    begin
      GraphWPF.Line(x - radius, y - radius, x + radius, y + radius, color);
      GraphWPF.Line(x - radius, y + radius, x + radius, y - radius, color);
    end;
  end;
  GraphWPF.Pen.Width := oldWidth;
end;

procedure DrawChart(chart: BaseGraphWPF; index: integer);
begin
  var rows := CurrentGrid.Rows;
  var columns := CurrentGrid.Columns;
  var row := index div columns;
  var column := index mod columns;
  if row >= rows then exit;

  var gap := CurrentGrid.Gap;
  var cellWidth := GraphWPF.Window.Width / columns;
  var cellHeight := GraphWPF.Window.Height / rows;
  var left := column * cellWidth + gap;
  var top := row * cellHeight + gap;
  var width := cellWidth - gap * 2;
  var height := cellHeight - gap * 2;
  var plotLeft := left + 52;
  var plotTop := top + 30;
  var plotWidth := Max(20, width - 70);
  var plotHeight := Max(20, height - 72);

  GraphWPF.FillRectangle(left, top, width, height, Colors.White);
  GraphWPF.DrawRectangle(left, top, width, height, Colors.LightGray);

  var xmin := System.Double.PositiveInfinity;
  var xmax := System.Double.NegativeInfinity;
  var ymin := System.Double.PositiveInfinity;
  var ymax := System.Double.NegativeInfinity;

  var fixedRange := chart.FPlotRect <> nil;
  if fixedRange then
  begin
    xmin := chart.FPlotRect.X;
    xmax := xmin + chart.FPlotRect.Width;
    ymin := chart.FPlotRect.Y;
    ymax := ymin + chart.FPlotRect.Height;
  end
  else
    foreach var series in chart.SeriesList do
    begin
      var count := Min(series.XValues.Length, series.YValues.Length);
      for var i := 0 to count - 1 do
        if IsFiniteValue(series.XValues[i]) and IsFiniteValue(series.YValues[i]) then
        begin
          xmin := Min(xmin, series.XValues[i]);
          xmax := Max(xmax, series.XValues[i]);
          ymin := Min(ymin, series.YValues[i]);
          ymax := Max(ymax, series.YValues[i]);
        end;
    end;

  if not IsFiniteValue(xmin) then (xmin, xmax, ymin, ymax) := (0.0, 1.0, 0.0, 1.0);
  if Abs(xmax - xmin) < 1e-12 then begin xmin -= 1; xmax += 1; end
  else if not fixedRange then begin var pad := (xmax - xmin) * 0.05; xmin -= pad; xmax += pad; end;
  if Abs(ymax - ymin) < 1e-12 then begin ymin -= 1; ymax += 1; end
  else if not fixedRange then begin var pad := (ymax - ymin) * 0.08; ymin -= pad; ymax += pad; end;

  var oldWidth := GraphWPF.Pen.Width;
  GraphWPF.Pen.Width := 1;
  for var tick := 0 to 5 do
  begin
    var px := plotLeft + plotWidth * tick / 5;
    var py := plotTop + plotHeight * tick / 5;
    GraphWPF.Line(px, plotTop, px, plotTop + plotHeight, integer($FFE7EBF0));
    GraphWPF.Line(plotLeft, py, plotLeft + plotWidth, py, integer($FFE7EBF0));
    GraphWPF.TextOut(px, plotTop + plotHeight + 7,
      TickText(xmin + (xmax - xmin) * tick / 5), Colors.DarkGray, Alignment.CenterTop);
    GraphWPF.TextOut(plotLeft - 7, plotTop + plotHeight - plotHeight * tick / 5,
      TickText(ymin + (ymax - ymin) * tick / 5), Colors.DarkGray, Alignment.RightCenter);
  end;

  if (xmin <= 0) and (xmax >= 0) then
    GraphWPF.Line(MapX(0, xmin, xmax, plotLeft, plotWidth), plotTop,
      MapX(0, xmin, xmax, plotLeft, plotWidth), plotTop + plotHeight, Colors.Gray);
  if (ymin <= 0) and (ymax >= 0) then
    GraphWPF.Line(plotLeft, MapY(0, ymin, ymax, plotTop, plotHeight),
      plotLeft + plotWidth, MapY(0, ymin, ymax, plotTop, plotHeight), Colors.Gray);
  GraphWPF.DrawRectangle(plotLeft, plotTop, plotWidth, plotHeight, Colors.Gray);

  foreach var series in chart.SeriesList do
  begin
    var count := Min(series.XValues.Length, series.YValues.Length);
    if series.Kind = PlotSeriesKind.LineSeries then
    begin
      var points := new List<Point>;
      for var i := 0 to count - 1 do
        if IsFiniteValue(series.XValues[i]) and IsFiniteValue(series.YValues[i]) then
          points.Add(GraphWPF.Pnt(
            MapX(series.XValues[i], xmin, xmax, plotLeft, plotWidth),
            MapY(series.YValues[i], ymin, ymax, plotTop, plotHeight)));
      if points.Count > 1 then
      begin
        GraphWPF.Pen.Width := series.Thickness;
        GraphWPF.PolyLine(points.ToArray, series.Color);
      end;
    end
    else
      for var i := 0 to count - 1 do
        if IsFiniteValue(series.XValues[i]) and IsFiniteValue(series.YValues[i]) then
          DrawMarker(MapX(series.XValues[i], xmin, xmax, plotLeft, plotWidth),
            MapY(series.YValues[i], ymin, ymax, plotTop, plotHeight),
            series.MarkerSize, series.Color, series.Marker, series.Thickness);
  end;

  GraphWPF.Pen.Width := oldWidth;
  if chart.FTitle <> '' then
    GraphWPF.TextOut(left + width / 2, top + 6, chart.FTitle,
      Colors.Black, Alignment.CenterTop);
end;

procedure RedrawAll;
begin
  if CurrentGrid = nil then exit;
  GraphWPF.SetStandardCoords(1, 0, 0);
  GraphWPF.Window.Clear(Colors.WhiteSmoke);
  var oldFontSize := GraphWPF.Font.Size;
  GraphWPF.Font.Size := 11;
  for var i := 0 to Charts.Count - 1 do
    DrawChart(Charts[i], i);
  GraphWPF.Font.Size := oldFontSize;
end;

begin
  GraphWPF.Window.Title := 'PlotWPF';
end.
