uses Graph3D;

begin
  Window.SetSize(800, 500);
  Window.Title := 'Graph3D browser test';
  View3D.BackgroundColor := RGB(15, 23, 42);

  var cube := Cube(-2.5, 0, 1, 2, Colors.RoyalBlue);
  cube.Rotate(V3D(0, 0, 1), 25);
  Sphere(0.3, 0, 1.1, 1.1, Colors.Gold);
  Cylinder(2.8, 0, 1.2, 2.4, 0.8, Colors.LightGreen);
  Cone(0, 3, 1.3, 2.6, 1.1, Colors.Coral);
end.
