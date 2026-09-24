// Browser compatibility implementation of the PascalABC.NET GraphWPF API.
// It intentionally contains no WPF dependencies: drawing commands cross the
// narrow PascalABC.Web.Graphics bridge and are rendered by Canvas 2D.
unit GraphWPF;

{$reference PascalABC.Web.Graphics.dll}

interface

uses PascalABC.Web.Graphics;

type
  Color = integer;
  GColor = Color;
  FontStyle = (Normal, Bold, Italic, BoldItalic);
  CoordType = (MathematicalCoords, StandardCoords);
  Alignment = (LeftTop, CenterTop, RightTop, LeftCenter, Center, RightCenter, LeftBottom, CenterBottom, RightBottom);

  Vector = class;

  Point = class
  public
    X, Y: real;
    constructor(x, y: real);
    static function operator+(p: Point; v: Vector): Point;
    static function operator-(p: Point; v: Vector): Point;
    static function operator-(p1, p2: Point): Vector;
    function ToString: string; override;
  end;

  GPoint = Point;

  Vector = class
  public
    X, Y: real;
    constructor(x, y: real);
    function Length: real;
    function Norm: Vector;
    static function operator+(v1, v2: Vector): Vector;
    static function operator-(v1, v2: Vector): Vector;
    static function operator*(v: Vector; value: real): Vector;
    static function operator*(value: real; v: Vector): Vector;
    static function operator/(v: Vector; value: real): Vector;
  end;

  Size = class
  public
    Width, Height: real;
    constructor(width, height: real);
  end;

  GRect = class
  public
    X, Y, Width, Height: real;
    constructor(x, y, width, height: real);
  end;

  Colors = static class
  public
    static Transparent: Color := integer($00000000);
    static Black: Color := integer($FF000000);
    static White: Color := integer($FFFFFFFF);
    static WhiteSmoke: Color := integer($FFF5F5F5);
    static Gray: Color := integer($FF808080);
    static LightGray: Color := integer($FFD3D3D3);
    static DarkGray: Color := integer($FFA9A9A9);
    static Red: Color := integer($FFFF0000);
    static DarkRed: Color := integer($FF8B0000);
    static Green: Color := integer($FF008000);
    static LightGreen: Color := integer($FF90EE90);
    static Blue: Color := integer($FF0000FF);
    static LightBlue: Color := integer($FFADD8E6);
    static RoyalBlue: Color := integer($FF4169E1);
    static SkyBlue: Color := integer($FF87CEEB);
    static Yellow: Color := integer($FFFFFF00);
    static Orange: Color := integer($FFFFA500);
    static Gold: Color := integer($FFFFD700);
    static Purple: Color := integer($FF800080);
    static Magenta: Color := integer($FFFF00FF);
    static Pink: Color := integer($FFFFC0CB);
    static Brown: Color := integer($FFA52A2A);
    static Beige: Color := integer($FFF5F5DC);
    static Bisque: Color := integer($FFFFE4C4);
    static Coral: Color := integer($FFFF7F50);
    static Cyan: Color := integer($FF00FFFF);
  end;

  Parameters = static class
  public
    static ArrowSizeAlong: real := 10;
    static ArrowSizeAcross: real := 4;
  end;

  BrushType = class
  public
    Color: GColor := Colors.White;
  end;

  PenType = class
  public
    Color: GColor := Colors.Black;
    Width: real := 1;
    X, Y: real;
    RoundCap: boolean := true;
  end;

  FontOptions = class
  public
    Color: GColor := Colors.Black;
    Name: string := 'Arial';
    Size: real := 14;
    Style: FontStyle := FontStyle.Normal;
    function WithStyle(style: FontStyle): FontOptions;
    function WithColor(color: GColor): FontOptions;
    function WithSize(size: real): FontOptions;
    function WithName(name: string): FontOptions;
  end;

  WindowTypeWPF = class
  private
    fWidth: real := 800;
    fHeight: real := 500;
    fTitle: string := 'GraphWPF';
    procedure SetWidth(value: real);
    procedure SetHeight(value: real);
    procedure SetTitle(value: string);
    function GetCenter: Point;
  public
    property Width: real read fWidth write SetWidth;
    property Height: real read fHeight write SetHeight;
    property Title: string read fTitle write SetTitle;
    property Center: Point read GetCenter;
    procedure SetSize(width, height: real);
    procedure CenterOnScreen;
    procedure Clear;
    procedure Clear(color: GColor);
  end;

  GraphWindowType = class
  public
    function GetWidth: real;
    function GetHeight: real;
    function Center: Point;
    function ClientRect: GRect;
    procedure Clear;
  end;

function RGB(r, g, b: byte): Color;
function ARGB(a, r, g, b: byte): Color;
function GrayColor(value: byte): Color;
function RandomColor: Color;
function EmptyColor: Color;
function clRandom: Color;
function Pnt(x, y: real): Point;
function Vect(x, y: real): Vector;
function Rect(x, y, width, height: real): GRect;

procedure SetPixel(x, y: real; color: Color);
procedure Line(x1, y1, x2, y2: real);
procedure Line(x1, y1, x2, y2: real; color: Color);
procedure Line(p1, p2: Point);
procedure Line(p1, p2: Point; color: Color);
procedure MoveTo(x, y: real);
procedure LineTo(x, y: real);
procedure MoveRel(dx, dy: real);
procedure LineRel(dx, dy: real);
procedure MoveBy(dx, dy: real);
procedure LineBy(dx, dy: real);
procedure MoveOn(dx, dy: real);
procedure LineOn(dx, dy: real);

procedure Rectangle(x, y, width, height: real);
procedure Rectangle(x, y, width, height: real; color: Color);
procedure DrawRectangle(x, y, width, height: real);
procedure DrawRectangle(x, y, width, height: real; color: Color);
procedure FillRectangle(x, y, width, height: real);
procedure FillRectangle(x, y, width, height: real; color: Color);

procedure Ellipse(x, y, radiusX, radiusY: real);
procedure Ellipse(x, y, radiusX, radiusY: real; color: Color);
procedure DrawEllipse(x, y, radiusX, radiusY: real);
procedure DrawEllipse(x, y, radiusX, radiusY: real; color: Color);
procedure FillEllipse(x, y, radiusX, radiusY: real);
procedure FillEllipse(x, y, radiusX, radiusY: real; color: Color);
procedure Circle(x, y, radius: real);
procedure Circle(x, y, radius: real; color: Color);
procedure Circle(p: Point; radius: real);
procedure Circle(p: Point; radius: real; color: Color);
procedure DrawCircle(x, y, radius: real);
procedure DrawCircle(x, y, radius: real; color: Color);
procedure FillCircle(x, y, radius: real);
procedure FillCircle(x, y, radius: real; color: Color);

procedure Arc(x, y, radius, angle1, angle2: real);
procedure Arc(x, y, radius, angle1, angle2: real; color: Color);
procedure Sector(x, y, radius, angle1, angle2: real);
procedure Sector(x, y, radius, angle1, angle2: real; color: Color);
procedure Pie(x, y, radius, angle1, angle2: real);
procedure Pie(x, y, radius, angle1, angle2: real; color: Color);

procedure PolyLine(points: array of Point);
procedure PolyLine(points: array of Point; color: Color);
procedure Polygon(points: array of Point);
procedure Polygon(points: array of Point; color: Color);
procedure DrawPolygon(points: array of Point);
procedure DrawPolygon(points: array of Point; color: Color);
procedure FillPolygon(points: array of Point);
procedure FillPolygon(points: array of Point; color: Color);
procedure Arrow(x1, y1, x2, y2: real);
procedure Arrow(x1, y1, x2, y2: real; color: Color);
procedure Arrow(p1, p2: Point);
procedure Arrow(p1, p2: Point; color: Color);

procedure TextOut(x, y: real; text: object; align: Alignment := Alignment.LeftTop; angle: real := 0);
procedure TextOut(x, y: real; text: object; color: GColor; align: Alignment := Alignment.LeftTop; angle: real := 0);
procedure TextOut(x, y: real; text: object; font: FontOptions; align: Alignment := Alignment.LeftTop; angle: real := 0);
procedure TextOut(position: Point; text: object; align: Alignment := Alignment.LeftTop; angle: real := 0);
procedure TextOut(position: Point; text: object; color: GColor; align: Alignment := Alignment.LeftTop; angle: real := 0);
function TextWidth(text: string): real;
function TextHeight(text: string): real;
function TextSize(text: string): Size;

procedure SetMathematicCoords(x1: real := -10; x2: real := 10; shouldDrawGrid: boolean := true);
procedure SetMathematicCoords(x1, x2, ymin: real; shouldDrawGrid: boolean := true);
procedure SetStandardCoords(scale: real := 1; x0: real := 0; y0: real := 0);
procedure DrawGrid;
function XMin: real;
function XMax: real;
function YMin: real;
function YMax: real;

var
  Brush: BrushType;
  Pen: PenType;
  Font: FontOptions;
  Window: WindowTypeWPF;
  GraphWindow: GraphWindowType;

implementation

var
  CurrentCoordType := CoordType.StandardCoords;
  GlobalScale := 1.0;
  XOrigin := 0.0;
  YOrigin := 0.0;

function ScreenX(x: real): real := XOrigin + x * GlobalScale;
function ScreenY(y: real): real := if CurrentCoordType = CoordType.MathematicalCoords then YOrigin - y * GlobalScale else YOrigin + y * GlobalScale;
function ScreenLength(value: real): real := Abs(value * GlobalScale);

constructor Point.Create(x, y: real);
begin
  Self.X := x;
  Self.Y := y;
end;

class function Point.operator+(p: Point; v: Vector): Point := new Point(p.X + v.X, p.Y + v.Y);
class function Point.operator-(p: Point; v: Vector): Point := new Point(p.X - v.X, p.Y - v.Y);
class function Point.operator-(p1, p2: Point): Vector := new Vector(p1.X - p2.X, p1.Y - p2.Y);
function Point.ToString: string := $'({X}; {Y})';

constructor Vector.Create(x, y: real);
begin
  Self.X := x;
  Self.Y := y;
end;

function Vector.Length: real := Sqrt(X * X + Y * Y);
function Vector.Norm: Vector := if Length = 0 then new Vector(0, 0) else Self / Length;
class function Vector.operator+(v1, v2: Vector): Vector := new Vector(v1.X + v2.X, v1.Y + v2.Y);
class function Vector.operator-(v1, v2: Vector): Vector := new Vector(v1.X - v2.X, v1.Y - v2.Y);
class function Vector.operator*(v: Vector; value: real): Vector := new Vector(v.X * value, v.Y * value);
class function Vector.operator*(value: real; v: Vector): Vector := v * value;
class function Vector.operator/(v: Vector; value: real): Vector := new Vector(v.X / value, v.Y / value);

constructor Size.Create(width, height: real) := (Self.Width, Self.Height) := (width, height);
constructor GRect.Create(x, y, width, height: real) := (Self.X, Self.Y, Self.Width, Self.Height) := (x, y, width, height);

function FontOptions.WithStyle(style: FontStyle): FontOptions;
begin
  Result := new FontOptions;
  (Result.Color, Result.Name, Result.Size, Result.Style) := (Color, Name, Size, style);
end;

function FontOptions.WithColor(color: GColor): FontOptions;
begin
  Result := new FontOptions;
  (Result.Color, Result.Name, Result.Size, Result.Style) := (color, Name, Size, Style);
end;

function FontOptions.WithSize(size: real): FontOptions;
begin
  Result := new FontOptions;
  (Result.Color, Result.Name, Result.Size, Result.Style) := (Color, Name, size, Style);
end;

function FontOptions.WithName(name: string): FontOptions;
begin
  Result := new FontOptions;
  (Result.Color, Result.Name, Result.Size, Result.Style) := (Color, name, Size, Style);
end;

procedure WindowTypeWPF.SetWidth(value: real) := SetSize(value, fHeight);
procedure WindowTypeWPF.SetHeight(value: real) := SetSize(fWidth, value);

procedure WindowTypeWPF.SetTitle(value: string);
begin
  fTitle := value;
  BrowserGraphicsBridge.SetTitle(value);
end;

function WindowTypeWPF.GetCenter: Point := new Point(fWidth / 2, fHeight / 2);

procedure WindowTypeWPF.SetSize(width, height: real);
begin
  fWidth := Max(1, width);
  fHeight := Max(1, height);
  BrowserGraphicsBridge.Resize(Round(fWidth), Round(fHeight));
end;

procedure WindowTypeWPF.CenterOnScreen := begin end;
procedure WindowTypeWPF.Clear := Clear(Colors.White);
procedure WindowTypeWPF.Clear(color: GColor) := BrowserGraphicsBridge.Clear(color);

function GraphWindowType.GetWidth: real := Window.Width;
function GraphWindowType.GetHeight: real := Window.Height;
function GraphWindowType.Center: Point := Window.Center;
function GraphWindowType.ClientRect: GRect := new GRect(0, 0, Window.Width, Window.Height);
procedure GraphWindowType.Clear := Window.Clear;

function RGB(r, g, b: byte): Color := integer($FF000000 or (integer(r) shl 16) or (integer(g) shl 8) or integer(b));
function ARGB(a, r, g, b: byte): Color := integer((integer(a) shl 24) or (integer(r) shl 16) or (integer(g) shl 8) or integer(b));
function GrayColor(value: byte): Color := RGB(value, value, value);
function RandomColor: Color := RGB(Random(256), Random(256), Random(256));
function EmptyColor: Color := Colors.Transparent;
function clRandom: Color := RandomColor;
function Pnt(x, y: real): Point := new Point(x, y);
function Vect(x, y: real): Vector := new Vector(x, y);
function Rect(x, y, width, height: real): GRect := new GRect(x, y, width, height);

procedure SetPixel(x, y: real; color: Color) := BrowserGraphicsBridge.Rectangle(ScreenX(x), ScreenY(y), 1, 1, color, color, 1, true, false);

procedure Line(x1, y1, x2, y2: real) := BrowserGraphicsBridge.Line(ScreenX(x1), ScreenY(y1), ScreenX(x2), ScreenY(y2), Pen.Color, Pen.Width);
procedure Line(x1, y1, x2, y2: real; color: Color) := BrowserGraphicsBridge.Line(ScreenX(x1), ScreenY(y1), ScreenX(x2), ScreenY(y2), color, Pen.Width);
procedure Line(p1, p2: Point) := Line(p1.X, p1.Y, p2.X, p2.Y);
procedure Line(p1, p2: Point; color: Color) := Line(p1.X, p1.Y, p2.X, p2.Y, color);
procedure MoveTo(x, y: real) := (Pen.X, Pen.Y) := (x, y);
procedure LineTo(x, y: real); begin Line(Pen.X, Pen.Y, x, y); MoveTo(x, y); end;
procedure MoveRel(dx, dy: real) := MoveTo(Pen.X + dx, Pen.Y + dy);
procedure LineRel(dx, dy: real) := LineTo(Pen.X + dx, Pen.Y + dy);
procedure MoveBy(dx, dy: real) := MoveRel(dx, dy);
procedure LineBy(dx, dy: real) := LineRel(dx, dy);
procedure MoveOn(dx, dy: real) := MoveRel(dx, dy);
procedure LineOn(dx, dy: real) := LineRel(dx, dy);

procedure DrawRectangleCore(x, y, width, height: real; fillColor, strokeColor: Color; fill, stroke: boolean) :=
  BrowserGraphicsBridge.Rectangle(ScreenX(x), ScreenY(y), width * GlobalScale, height * GlobalScale, fillColor, strokeColor, Pen.Width, fill, stroke);
procedure Rectangle(x, y, width, height: real) := DrawRectangleCore(x, y, width, height, Brush.Color, Pen.Color, true, true);
procedure Rectangle(x, y, width, height: real; color: Color) := DrawRectangleCore(x, y, width, height, color, Pen.Color, true, true);
procedure DrawRectangle(x, y, width, height: real) := DrawRectangleCore(x, y, width, height, Brush.Color, Pen.Color, false, true);
procedure DrawRectangle(x, y, width, height: real; color: Color) := DrawRectangleCore(x, y, width, height, Brush.Color, color, false, true);
procedure FillRectangle(x, y, width, height: real) := DrawRectangleCore(x, y, width, height, Brush.Color, Pen.Color, true, false);
procedure FillRectangle(x, y, width, height: real; color: Color) := DrawRectangleCore(x, y, width, height, color, Pen.Color, true, false);

procedure DrawEllipseCore(x, y, radiusX, radiusY: real; fillColor, strokeColor: Color; fill, stroke: boolean) :=
  BrowserGraphicsBridge.Ellipse(ScreenX(x), ScreenY(y), ScreenLength(radiusX), ScreenLength(radiusY), fillColor, strokeColor, Pen.Width, fill, stroke);
procedure Ellipse(x, y, radiusX, radiusY: real) := DrawEllipseCore(x, y, radiusX, radiusY, Brush.Color, Pen.Color, true, true);
procedure Ellipse(x, y, radiusX, radiusY: real; color: Color) := DrawEllipseCore(x, y, radiusX, radiusY, color, Pen.Color, true, true);
procedure DrawEllipse(x, y, radiusX, radiusY: real) := DrawEllipseCore(x, y, radiusX, radiusY, Brush.Color, Pen.Color, false, true);
procedure DrawEllipse(x, y, radiusX, radiusY: real; color: Color) := DrawEllipseCore(x, y, radiusX, radiusY, Brush.Color, color, false, true);
procedure FillEllipse(x, y, radiusX, radiusY: real) := DrawEllipseCore(x, y, radiusX, radiusY, Brush.Color, Pen.Color, true, false);
procedure FillEllipse(x, y, radiusX, radiusY: real; color: Color) := DrawEllipseCore(x, y, radiusX, radiusY, color, Pen.Color, true, false);
procedure Circle(x, y, radius: real) := Ellipse(x, y, radius, radius);
procedure Circle(x, y, radius: real; color: Color) := Ellipse(x, y, radius, radius, color);
procedure Circle(p: Point; radius: real) := Circle(p.X, p.Y, radius);
procedure Circle(p: Point; radius: real; color: Color) := Circle(p.X, p.Y, radius, color);
procedure DrawCircle(x, y, radius: real) := DrawEllipse(x, y, radius, radius);
procedure DrawCircle(x, y, radius: real; color: Color) := DrawEllipse(x, y, radius, radius, color);
procedure FillCircle(x, y, radius: real) := FillEllipse(x, y, radius, radius);
procedure FillCircle(x, y, radius: real; color: Color) := FillEllipse(x, y, radius, radius, color);

procedure Arc(x, y, radius, angle1, angle2: real) := BrowserGraphicsBridge.Arc(ScreenX(x), ScreenY(y), ScreenLength(radius), angle1, angle2, Brush.Color, Pen.Color, Pen.Width, false, false, true);
procedure Arc(x, y, radius, angle1, angle2: real; color: Color) := BrowserGraphicsBridge.Arc(ScreenX(x), ScreenY(y), ScreenLength(radius), angle1, angle2, Brush.Color, color, Pen.Width, false, false, true);
procedure Sector(x, y, radius, angle1, angle2: real) := BrowserGraphicsBridge.Arc(ScreenX(x), ScreenY(y), ScreenLength(radius), angle1, angle2, Brush.Color, Pen.Color, Pen.Width, true, true, true);
procedure Sector(x, y, radius, angle1, angle2: real; color: Color) := BrowserGraphicsBridge.Arc(ScreenX(x), ScreenY(y), ScreenLength(radius), angle1, angle2, color, Pen.Color, Pen.Width, true, true, true);
procedure Pie(x, y, radius, angle1, angle2: real) := Sector(x, y, radius, angle1, angle2);
procedure Pie(x, y, radius, angle1, angle2: real; color: Color) := Sector(x, y, radius, angle1, angle2, color);

function Flatten(points: array of Point): array of real;
begin
  SetLength(Result, points.Length * 2);
  for var index := 0 to points.Length - 1 do
  begin
    Result[index * 2] := ScreenX(points[index].X);
    Result[index * 2 + 1] := ScreenY(points[index].Y);
  end;
end;

procedure PolyLine(points: array of Point) := BrowserGraphicsBridge.Polygon(Flatten(points), Brush.Color, Pen.Color, Pen.Width, false, true);
procedure PolyLine(points: array of Point; color: Color) := BrowserGraphicsBridge.Polygon(Flatten(points), Brush.Color, color, Pen.Width, false, true);
procedure Polygon(points: array of Point) := BrowserGraphicsBridge.Polygon(Flatten(points), Brush.Color, Pen.Color, Pen.Width, true, true);
procedure Polygon(points: array of Point; color: Color) := BrowserGraphicsBridge.Polygon(Flatten(points), color, Pen.Color, Pen.Width, true, true);
procedure DrawPolygon(points: array of Point) := BrowserGraphicsBridge.Polygon(Flatten(points), Brush.Color, Pen.Color, Pen.Width, false, true);
procedure DrawPolygon(points: array of Point; color: Color) := BrowserGraphicsBridge.Polygon(Flatten(points), Brush.Color, color, Pen.Width, false, true);
procedure FillPolygon(points: array of Point) := BrowserGraphicsBridge.Polygon(Flatten(points), Brush.Color, Pen.Color, Pen.Width, true, false);
procedure FillPolygon(points: array of Point; color: Color) := BrowserGraphicsBridge.Polygon(Flatten(points), color, Pen.Color, Pen.Width, true, false);

procedure Arrow(x1, y1, x2, y2: real; color: Color);
begin
  Line(x1, y1, x2, y2, color);
  var direction := Vect(x2 - x1, y2 - y1).Norm;
  var side := Vect(-direction.Y, direction.X);
  var basePoint := Pnt(x2, y2) - direction * Parameters.ArrowSizeAlong;
  FillPolygon(Arr(Pnt(x2, y2), basePoint + side * Parameters.ArrowSizeAcross, basePoint - side * Parameters.ArrowSizeAcross), color);
end;

procedure Arrow(x1, y1, x2, y2: real) := Arrow(x1, y1, x2, y2, Pen.Color);
procedure Arrow(p1, p2: Point) := Arrow(p1.X, p1.Y, p2.X, p2.Y);
procedure Arrow(p1, p2: Point; color: Color) := Arrow(p1.X, p1.Y, p2.X, p2.Y, color);

function AlignmentName(align: Alignment): string;
begin
  case align of
    Alignment.LeftTop: Result := 'left-top';
    Alignment.CenterTop: Result := 'center-top';
    Alignment.RightTop: Result := 'right-top';
    Alignment.LeftCenter: Result := 'left-center';
    Alignment.Center: Result := 'center-center';
    Alignment.RightCenter: Result := 'right-center';
    Alignment.LeftBottom: Result := 'left-bottom';
    Alignment.CenterBottom: Result := 'center-bottom';
    Alignment.RightBottom: Result := 'right-bottom';
  end;
end;

function FontStyleName(style: FontStyle): string;
begin
  case style of
    FontStyle.Bold: Result := 'bold';
    FontStyle.Italic: Result := 'italic';
    FontStyle.BoldItalic: Result := 'bold-italic';
    else Result := 'normal';
  end;
end;

procedure DrawTextInternal(x, y: real; text: object; font: FontOptions; align: Alignment; angle: real) :=
  BrowserGraphicsBridge.Text(ScreenX(x), ScreenY(y), if text = nil then '' else text.ToString, font.Color, font.Size, font.Name, FontStyleName(font.Style), AlignmentName(align), angle);
procedure TextOut(x, y: real; text: object; align: Alignment; angle: real) := DrawTextInternal(x, y, text, Font, align, angle);
procedure TextOut(x, y: real; text: object; color: GColor; align: Alignment; angle: real) := DrawTextInternal(x, y, text, Font.WithColor(color), align, angle);
procedure TextOut(x, y: real; text: object; font: FontOptions; align: Alignment; angle: real) := DrawTextInternal(x, y, text, font, align, angle);
procedure TextOut(position: Point; text: object; align: Alignment; angle: real) := TextOut(position.X, position.Y, text, align, angle);
procedure TextOut(position: Point; text: object; color: GColor; align: Alignment; angle: real) := TextOut(position.X, position.Y, text, color, align, angle);
function TextWidth(text: string): real := text.Length * Font.Size * 0.6;
function TextHeight(text: string): real := Font.Size * 1.2;
function TextSize(text: string): Size := new Size(TextWidth(text), TextHeight(text));

procedure SetMathematicCoords(x1: real; x2: real; shouldDrawGrid: boolean);
begin
  CurrentCoordType := CoordType.MathematicalCoords;
  GlobalScale := Window.Width / (x2 - x1);
  XOrigin := -x1 * GlobalScale;
  YOrigin := Window.Height / 2;
  Window.Clear;
  if shouldDrawGrid then DrawGrid;
end;

procedure SetMathematicCoords(x1, x2, ymin: real; shouldDrawGrid: boolean);
begin
  SetMathematicCoords(x1, x2, false);
  YOrigin := Window.Height + ymin * GlobalScale;
  Window.Clear;
  if shouldDrawGrid then DrawGrid;
end;

procedure SetStandardCoords(scale: real; x0: real; y0: real);
begin
  CurrentCoordType := CoordType.StandardCoords;
  GlobalScale := scale;
  XOrigin := x0;
  YOrigin := y0;
end;

procedure DrawGrid;
begin
  var oldColor := Pen.Color;
  var oldWidth := Pen.Width;
  Pen.Color := integer($FFDCE3EC);
  Pen.Width := 1;
  var xmin := Floor(XMin);
  var xmax := Ceil(XMax);
  var ymin := Floor(YMin);
  var ymax := Ceil(YMax);
  for var x := xmin to xmax do Line(x, YMin, x, YMax);
  for var y := ymin to ymax do Line(XMin, y, XMax, y);
  Pen.Color := integer($FF7A8798);
  Line(XMin, 0, XMax, 0);
  Line(0, YMin, 0, YMax);
  Pen.Color := oldColor;
  Pen.Width := oldWidth;
end;

function XMin: real := -XOrigin / GlobalScale;
function XMax: real := (Window.Width - XOrigin) / GlobalScale;
function YMin: real := if CurrentCoordType = CoordType.MathematicalCoords then (YOrigin - Window.Height) / GlobalScale else -YOrigin / GlobalScale;
function YMax: real := if CurrentCoordType = CoordType.MathematicalCoords then YOrigin / GlobalScale else (Window.Height - YOrigin) / GlobalScale;

begin
  Brush := new BrushType;
  Pen := new PenType;
  Font := new FontOptions;
  Window := new WindowTypeWPF;
  GraphWindow := new GraphWindowType;
  BrowserGraphicsBridge.Open(Round(Window.Width), Round(Window.Height), Window.Title);
  Window.Clear;
end.
