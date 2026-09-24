begin
  // Ученик видит и редактирует только эту программу-решение.
  // LightPT и Tasks подключаются сайтом автоматически.
  var count := ReadInteger;
  var values := ArrGen(count, i -> ReadInteger);
  var divisibleByFour := values.Count(value -> value mod 4 = 0);

  Println(divisibleByFour);
end.
