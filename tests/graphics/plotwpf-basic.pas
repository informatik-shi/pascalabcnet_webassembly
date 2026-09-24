uses PlotWPF;

begin
  var grid := new GridWPF(1, 2, 10);

  var line := new LineGraphWPF(-Pi, Pi, x -> Sin(x), Colors.RoyalBlue);
  line.Title := 'Синус';
  line.Graph[0].Thickness := 3;
  line.AddLineGraph(-Pi, Pi, x -> Cos(x), Colors.Coral);
  line.Graph[1].ChangeData(-Pi, Pi, x -> Cos(x) * 0.8);

  var points := new MarkerGraphWPF(
    Arr(1.0, 2.0, 3.0, 4.0, 5.0), Arr(2.0, 5.0, 3.0, 7.0, 4.0),
    Colors.Green, MarkerType.Diamond, 10);
  points.Title := 'Наблюдения';
  points.PlotRect := Rect(0.5, 1, 5, 7);
  points.Graph[0].Color := Colors.Green;
  points.AddLineGraph(Arr(1.0, 2.0, 3.0, 4.0, 5.0),
    Arr(2.0, 5.0, 3.0, 7.0, 4.0), Colors.LightGreen);
end.
