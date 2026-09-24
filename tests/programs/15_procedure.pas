procedure Increment(var value: integer);
begin
  value += 1;
end;

begin
  var n := 41;
  Increment(n);
  Println(n);
end.
