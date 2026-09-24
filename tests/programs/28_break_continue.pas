begin
  var sum := 0;
  for var i := 1 to 10 do
  begin
    if i = 3 then continue;
    if i = 6 then break;
    sum += i;
  end;
  Println(sum);
end.
