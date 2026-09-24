begin
  var n := 5;
  var product := 1;
  while n > 0 do
  begin
    product *= n;
    n -= 1;
  end;
  Println(product);
end.
