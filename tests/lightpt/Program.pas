begin
  var values := Arr(3, 8, 12, 5, 16);
  Println(values.Count(value -> value mod 4 = 0));
end.
