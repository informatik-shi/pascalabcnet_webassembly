// Browser compatibility implementation of the most-used PascalABC.NET Graph3D API.
// The public surface intentionally avoids WPF/HelixToolkit dependencies. Commands
// are sent to the browser-safe bridge and rendered with WebGL 2 in the page canvas.
unit Graph3D;

{$reference PascalABC.Web.Graphics.dll}

interface

uses GraphWPF, PascalABC.Web.Graphics;

type
  Material = Color;
  GMaterial = Material;
  Colors = GraphWPF.Colors;

  Vector3D = class;

  Point3D = class
  public
    X, Y, Z: real;
    constructor(x, y, z: real);
    static function operator+(p: Point3D; v: Vector3D): Point3D;
    static function operator-(p1, p2: Point3D): Vector3D;
    function DistanceTo(p: Point3D): real;
    function ToString: string; override;
  end;

  Vector3D = class
  public
    X, Y, Z: real;
    constructor(x, y, z: real);
    function Length: real;
    function Norm: Vector3D;
    static function operator+(a, b: Vector3D): Vector3D;
    static function operator-(a, b: Vector3D): Vector3D;
    static function operator*(v: Vector3D; k: real): Vector3D;
    static function operator*(k: real; v: Vector3D): Vector3D;
    static function operator/(v: Vector3D; k: real): Vector3D;
  end;

  Size3D = class
  public
    X, Y, Z: real;
    constructor(x, y, z: real);
  end;

  Object3D = class
  private
    fId: integer;
    fX, fY, fZ: real;
    fColor: GColor;
    procedure SetX(value: real);
    procedure SetY(value: real);
    procedure SetZ(value: real);
    procedure SetColor(value: GColor);
    function GetPosition: Point3D;
    procedure SetPosition(value: Point3D);
  protected
    constructor Create(shape: string; x, y, z, sx, sy, sz: real; color: GColor; topScale: real := 1);
  public
    property X: real read fX write SetX;
    property Y: real read fY write SetY;
    property Z: real read fZ write SetZ;
    property Position: Point3D read GetPosition write SetPosition;
    property Color: GColor read fColor write SetColor;
    function MoveTo(x, y, z: real): Object3D;
    function MoveTo(p: Point3D): Object3D;
    function MoveBy(dx, dy, dz: real): Object3D;
    function MoveBy(v: Vector3D): Object3D;
    function MoveByX(dx: real): Object3D;
    function MoveByY(dy: real): Object3D;
    function MoveByZ(dz: real): Object3D;
    function MoveOn(dx, dy, dz: real): Object3D;
    function Scale(f: real): Object3D;
    function ScaleX(f: real): Object3D;
    function ScaleY(f: real): Object3D;
    function ScaleZ(f: real): Object3D;
    function Rotate(axis: Vector3D; angle: real): Object3D;
    procedure Remove;
  end;

  SphereT = class(Object3D)
  public
    Radius: real;
    constructor(x, y, z, radius: real; material: Material);
  end;

  CubeT = class(Object3D)
  public
    SideLength: real;
    constructor(x, y, z, sideLength: real; material: Material);
  end;

  BoxT = class(Object3D)
  public
    Length, Width, Height: real;
    constructor(x, y, z, sizeX, sizeY, sizeZ: real; material: Material);
  end;

  TruncatedConeT = class(Object3D)
  public
    Height, Radius, TopRadius: real;
    constructor(x, y, z, height, radius, topRadius: real; material: Material);
  end;

  CylinderT = class(TruncatedConeT);
  CoordinateSystemT = class
  end;

  View3DType = class
  private
    fShowGridLines := true;
    fShowCoordinateSystem := true;
    fShowViewCube := false;
    fBackgroundColor: Color := integer($FF101827);
    fTitle := 'Graph3D';
    fSubTitle := '';
    procedure Apply;
    procedure SetShowGridLines(value: boolean);
    procedure SetShowCoordinateSystem(value: boolean);
    procedure SetShowViewCube(value: boolean);
    procedure SetBackgroundColor(value: Color);
    procedure SetTitle(value: string);
  public
    property ShowGridLines: boolean read fShowGridLines write SetShowGridLines;
    property ShowCoordinateSystem: boolean read fShowCoordinateSystem write SetShowCoordinateSystem;
    property ShowViewCube: boolean read fShowViewCube write SetShowViewCube;
    property BackgroundColor: Color read fBackgroundColor write SetBackgroundColor;
    property Title: string read fTitle write SetTitle;
    property SubTitle: string read fSubTitle write fSubTitle;
    procedure HideAll;
  end;

  CameraType = class
  private
    fPosition: Point3D;
    fTarget: Point3D;
    procedure Apply;
    procedure SetPosition(value: Point3D);
    procedure SetTarget(value: Point3D);
    function GetLookDirection: Vector3D;
    procedure SetLookDirection(value: Vector3D);
  public
    constructor;
    property Position: Point3D read fPosition write SetPosition;
    property Target: Point3D read fTarget write SetTarget;
    property LookDirection: Vector3D read GetLookDirection write SetLookDirection;
    procedure MoveBy(dx, dy, dz: real);
    procedure MoveBy(v: Vector3D);
    procedure LookAt(x, y, z: real);
    procedure LookAt(p: Point3D);
  end;

  WindowType3D = class
  private
    fWidth := 800.0;
    fHeight := 500.0;
    fTitle := 'Graph3D';
    procedure SetWidth(value: real);
    procedure SetHeight(value: real);
    procedure SetTitle(value: string);
  public
    property Width: real read fWidth write SetWidth;
    property Height: real read fHeight write SetHeight;
    property Title: string read fTitle write SetTitle;
    procedure SetSize(width, height: real);
    procedure Clear;
  end;

function P3D(x, y, z: real): Point3D;
function V3D(x, y, z: real): Vector3D;
function Sz3D(x, y, z: real): Size3D;
function RGB(r, g, b: byte): Color;
function ARGB(a, r, g, b: byte): Color;
function RandomColor: Color;
function DiffuseMaterial(color: Color): Material;
function EmissiveMaterial(color: Color): Material;
function DefaultMaterial: Material;
function Sphere(x, y, z, radius: real; material: Material := 0): SphereT;
function Sphere(center: Point3D; radius: real; material: Material := 0): SphereT;
function Cube(x, y, z, sideLength: real; material: Material := 0): CubeT;
function Cube(center: Point3D; sideLength: real; material: Material := 0): CubeT;
function Box(x, y, z, sizeX, sizeY, sizeZ: real; material: Material := 0): BoxT;
function Box(center: Point3D; size: Size3D; material: Material := 0): BoxT;
function TruncatedCone(x, y, z, height, radius, topRadius: real; topcap: boolean; material: Material := 0): TruncatedConeT;
function TruncatedCone(x, y, z, height, radius, topRadius: real; material: Material := 0): TruncatedConeT;
function TruncatedCone(p: Point3D; height, radius, topRadius: real; material: Material := 0): TruncatedConeT;
function Cylinder(x, y, z, height, radius: real; topcap: boolean; material: Material := 0): CylinderT;
function Cylinder(x, y, z, height, radius: real; material: Material := 0): CylinderT;
function Cylinder(p: Point3D; height, radius: real; material: Material := 0): CylinderT;
function Cone(x, y, z, height, radius: real; material: Material := 0): TruncatedConeT;
function Cone(p: Point3D; height, radius: real; material: Material := 0): TruncatedConeT;
function CoordinateSystem(arrowsLength: real := 2): CoordinateSystemT;

var
  View3D: View3DType;
  Camera: CameraType;
  Window: WindowType3D;

implementation

function EffectiveMaterial(value: Material): Color := if value = 0 then Colors.RoyalBlue else value;

constructor Point3D.Create(x, y, z: real);
begin
  Self.X := x; Self.Y := y; Self.Z := z;
end;

class function Point3D.operator+(p: Point3D; v: Vector3D): Point3D := new Point3D(p.X + v.X, p.Y + v.Y, p.Z + v.Z);
class function Point3D.operator-(p1, p2: Point3D): Vector3D := new Vector3D(p1.X - p2.X, p1.Y - p2.Y, p1.Z - p2.Z);
function Point3D.DistanceTo(p: Point3D): real := Sqrt(Sqr(X - p.X) + Sqr(Y - p.Y) + Sqr(Z - p.Z));
function Point3D.ToString: string := $'({X}; {Y}; {Z})';

constructor Vector3D.Create(x, y, z: real);
begin
  Self.X := x; Self.Y := y; Self.Z := z;
end;

function Vector3D.Length: real := Sqrt(X * X + Y * Y + Z * Z);
function Vector3D.Norm: Vector3D := if Length = 0 then new Vector3D(0, 0, 0) else Self / Length;
class function Vector3D.operator+(a, b: Vector3D): Vector3D := new Vector3D(a.X + b.X, a.Y + b.Y, a.Z + b.Z);
class function Vector3D.operator-(a, b: Vector3D): Vector3D := new Vector3D(a.X - b.X, a.Y - b.Y, a.Z - b.Z);
class function Vector3D.operator*(v: Vector3D; k: real): Vector3D := new Vector3D(v.X * k, v.Y * k, v.Z * k);
class function Vector3D.operator*(k: real; v: Vector3D): Vector3D := v * k;
class function Vector3D.operator/(v: Vector3D; k: real): Vector3D := new Vector3D(v.X / k, v.Y / k, v.Z / k);

constructor Size3D.Create(x, y, z: real);
begin
  Self.X := x; Self.Y := y; Self.Z := z;
end;

constructor Object3D.Create(shape: string; x, y, z, sx, sy, sz: real; color: GColor; topScale: real);
begin
  fX := x; fY := y; fZ := z;
  fColor := EffectiveMaterial(color);
  fId := BrowserGraphicsBridge.Create3D(shape, x, y, z, sx, sy, sz, fColor, topScale);
end;

procedure Object3D.SetX(value: real) := MoveTo(value, fY, fZ);
procedure Object3D.SetY(value: real) := MoveTo(fX, value, fZ);
procedure Object3D.SetZ(value: real) := MoveTo(fX, fY, value);
procedure Object3D.SetColor(value: GColor);
begin
  fColor := value;
  BrowserGraphicsBridge.SetColor3D(fId, value);
end;
function Object3D.GetPosition: Point3D := P3D(fX, fY, fZ);
procedure Object3D.SetPosition(value: Point3D) := MoveTo(value);

function Object3D.MoveTo(x, y, z: real): Object3D;
begin
  fX := x; fY := y; fZ := z;
  BrowserGraphicsBridge.Move3D(fId, x, y, z);
  Result := Self;
end;
function Object3D.MoveTo(p: Point3D): Object3D := MoveTo(p.X, p.Y, p.Z);
function Object3D.MoveBy(dx, dy, dz: real): Object3D := MoveTo(fX + dx, fY + dy, fZ + dz);
function Object3D.MoveBy(v: Vector3D): Object3D := MoveBy(v.X, v.Y, v.Z);
function Object3D.MoveByX(dx: real): Object3D := MoveBy(dx, 0, 0);
function Object3D.MoveByY(dy: real): Object3D := MoveBy(0, dy, 0);
function Object3D.MoveByZ(dz: real): Object3D := MoveBy(0, 0, dz);
function Object3D.MoveOn(dx, dy, dz: real): Object3D := MoveBy(dx, dy, dz);
function Object3D.Scale(f: real): Object3D;
begin BrowserGraphicsBridge.Scale3D(fId, f, f, f); Result := Self; end;
function Object3D.ScaleX(f: real): Object3D;
begin BrowserGraphicsBridge.Scale3D(fId, f, 1, 1); Result := Self; end;
function Object3D.ScaleY(f: real): Object3D;
begin BrowserGraphicsBridge.Scale3D(fId, 1, f, 1); Result := Self; end;
function Object3D.ScaleZ(f: real): Object3D;
begin BrowserGraphicsBridge.Scale3D(fId, 1, 1, f); Result := Self; end;
function Object3D.Rotate(axis: Vector3D; angle: real): Object3D;
begin BrowserGraphicsBridge.Rotate3D(fId, axis.X, axis.Y, axis.Z, angle); Result := Self; end;
procedure Object3D.Remove := BrowserGraphicsBridge.Remove3D(fId);

constructor SphereT.Create(x, y, z, radius: real; material: Material);
begin inherited Create('sphere', x, y, z, radius * 2, radius * 2, radius * 2, material); Radius := radius; end;
constructor CubeT.Create(x, y, z, sideLength: real; material: Material);
begin inherited Create('cube', x, y, z, sideLength, sideLength, sideLength, material); SideLength := sideLength; end;
constructor BoxT.Create(x, y, z, sizeX, sizeY, sizeZ: real; material: Material);
begin inherited Create('cube', x, y, z, sizeX, sizeY, sizeZ, material); Length := sizeX; Width := sizeY; Height := sizeZ; end;
constructor TruncatedConeT.Create(x, y, z, height, radius, topRadius: real; material: Material);
begin
  inherited Create('cylinder', x, y, z, radius * 2, radius * 2, height, material, if radius = 0 then 0 else topRadius / radius);
  Self.Height := height; Self.Radius := radius; Self.TopRadius := topRadius;
end;

procedure View3DType.Apply := BrowserGraphicsBridge.SetView3D(fShowGridLines, fShowCoordinateSystem, fBackgroundColor);
procedure View3DType.SetShowGridLines(value: boolean); begin fShowGridLines := value; Apply; end;
procedure View3DType.SetShowCoordinateSystem(value: boolean); begin fShowCoordinateSystem := value; Apply; end;
procedure View3DType.SetShowViewCube(value: boolean) := fShowViewCube := value;
procedure View3DType.SetBackgroundColor(value: Color); begin fBackgroundColor := value; Apply; end;
procedure View3DType.SetTitle(value: string); begin fTitle := value; BrowserGraphicsBridge.SetTitle(value); end;
procedure View3DType.HideAll;
begin fShowGridLines := false; fShowCoordinateSystem := false; fShowViewCube := false; Apply; end;

constructor CameraType.Create;
begin fPosition := P3D(9, -11, 8); fTarget := P3D(0, 0, 0); end;
procedure CameraType.Apply := BrowserGraphicsBridge.SetCamera3D(fPosition.X, fPosition.Y, fPosition.Z, fTarget.X, fTarget.Y, fTarget.Z);
procedure CameraType.SetPosition(value: Point3D); begin fPosition := value; Apply; end;
procedure CameraType.SetTarget(value: Point3D); begin fTarget := value; Apply; end;
function CameraType.GetLookDirection: Vector3D := fTarget - fPosition;
procedure CameraType.SetLookDirection(value: Vector3D); begin fTarget := fPosition + value; Apply; end;
procedure CameraType.MoveBy(dx, dy, dz: real); begin fPosition := fPosition + V3D(dx, dy, dz); fTarget := fTarget + V3D(dx, dy, dz); Apply; end;
procedure CameraType.MoveBy(v: Vector3D) := MoveBy(v.X, v.Y, v.Z);
procedure CameraType.LookAt(x, y, z: real) := SetTarget(P3D(x, y, z));
procedure CameraType.LookAt(p: Point3D) := SetTarget(p);

procedure WindowType3D.SetWidth(value: real) := SetSize(value, fHeight);
procedure WindowType3D.SetHeight(value: real) := SetSize(fWidth, value);
procedure WindowType3D.SetTitle(value: string); begin fTitle := value; BrowserGraphicsBridge.SetTitle(value); end;
procedure WindowType3D.SetSize(width, height: real);
begin fWidth := Max(1, width); fHeight := Max(1, height); BrowserGraphicsBridge.Resize(Round(fWidth), Round(fHeight)); end;
procedure WindowType3D.Clear;
begin
  BrowserGraphicsBridge.Open3D(Round(fWidth), Round(fHeight), fTitle, View3D.BackgroundColor);
  View3D.Apply;
  Camera.Apply;
end;

function P3D(x, y, z: real): Point3D := new Point3D(x, y, z);
function V3D(x, y, z: real): Vector3D := new Vector3D(x, y, z);
function Sz3D(x, y, z: real): Size3D := new Size3D(x, y, z);
function RGB(r, g, b: byte): Color := GraphWPF.RGB(r, g, b);
function ARGB(a, r, g, b: byte): Color := GraphWPF.ARGB(a, r, g, b);
function RandomColor: Color := GraphWPF.RandomColor;
function DiffuseMaterial(color: Color): Material := color;
function EmissiveMaterial(color: Color): Material := color;
function DefaultMaterial: Material := Colors.RoyalBlue;
function Sphere(x, y, z, radius: real; material: Material): SphereT := new SphereT(x, y, z, radius, material);
function Sphere(center: Point3D; radius: real; material: Material): SphereT := Sphere(center.X, center.Y, center.Z, radius, material);
function Cube(x, y, z, sideLength: real; material: Material): CubeT := new CubeT(x, y, z, sideLength, material);
function Cube(center: Point3D; sideLength: real; material: Material): CubeT := Cube(center.X, center.Y, center.Z, sideLength, material);
function Box(x, y, z, sizeX, sizeY, sizeZ: real; material: Material): BoxT := new BoxT(x, y, z, sizeX, sizeY, sizeZ, material);
function Box(center: Point3D; size: Size3D; material: Material): BoxT := Box(center.X, center.Y, center.Z, size.X, size.Y, size.Z, material);
function TruncatedCone(x, y, z, height, radius, topRadius: real; topcap: boolean; material: Material): TruncatedConeT := new TruncatedConeT(x, y, z, height, radius, topRadius, material);
function TruncatedCone(x, y, z, height, radius, topRadius: real; material: Material): TruncatedConeT := TruncatedCone(x, y, z, height, radius, topRadius, true, material);
function TruncatedCone(p: Point3D; height, radius, topRadius: real; material: Material): TruncatedConeT := TruncatedCone(p.X, p.Y, p.Z, height, radius, topRadius, true, material);
function Cylinder(x, y, z, height, radius: real; topcap: boolean; material: Material): CylinderT;
begin Result := new CylinderT(x, y, z, height, radius, radius, material); end;
function Cylinder(x, y, z, height, radius: real; material: Material): CylinderT := Cylinder(x, y, z, height, radius, true, material);
function Cylinder(p: Point3D; height, radius: real; material: Material): CylinderT := Cylinder(p.X, p.Y, p.Z, height, radius, true, material);
function Cone(x, y, z, height, radius: real; material: Material): TruncatedConeT := TruncatedCone(x, y, z, height, radius, 0, true, material);
function Cone(p: Point3D; height, radius: real; material: Material): TruncatedConeT := Cone(p.X, p.Y, p.Z, height, radius, material);
function CoordinateSystem(arrowsLength: real): CoordinateSystemT;
begin
  View3D.ShowCoordinateSystem := true;
  Result := new CoordinateSystemT;
end;

begin
  View3D := new View3DType;
  Camera := new CameraType;
  Window := new WindowType3D;
  BrowserGraphicsBridge.Open3D(Round(Window.Width), Round(Window.Height), Window.Title, View3D.BackgroundColor);
  View3D.Apply;
  Camera.Apply;
end.
