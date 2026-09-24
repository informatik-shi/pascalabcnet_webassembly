begin
  var count := ReadInteger;
  var values := ArrGen(count, i -> ReadInteger);
  Println(values.Count(value -> value mod 4 = 0));
end.
