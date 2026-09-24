uses GraphWPF;

begin
  Window.SetSize(800, 500);
  Window.Title := 'GraphWPF в браузере';
  Window.Clear(Colors.WhiteSmoke);

  Pen.Width := 3;
  Pen.Color := Colors.RoyalBlue;
  Brush.Color := RGB(210, 230, 255);
  Rectangle(60, 70, 250, 150);

  Brush.Color := Colors.Gold;
  Circle(440, 145, 75);
  Line(60, 280, 680, 280, Colors.DarkGray);

  var points := Arr(Pnt(540, 370), Pnt(610, 310), Pnt(680, 370), Pnt(650, 440), Pnt(570, 440));
  Brush.Color := Colors.LightGreen;
  Polygon(points);

  Font.Size := 26;
  Font.Color := Colors.DarkRed;
  TextOut(185, 145, 'PascalABC.NET', Alignment.Center);
  Font.Size := 18;
  Font.Color := Colors.Black;
  TextOut(440, 145, 'Canvas 2D', Alignment.Center);
end.
