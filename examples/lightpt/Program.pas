begin
  // Ученик видит и редактирует только эту программу.
  var values := Arr(3, 8, 12, 5, 16);
  var divisibleByFour := values.Count(value -> value mod 4 = 0);

  Println(divisibleByFour);
end.
