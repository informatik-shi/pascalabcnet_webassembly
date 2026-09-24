function Factorial(n: integer): integer;
begin
  if n <= 1 then Result := 1
  else Result := n * Factorial(n - 1);
end;

begin
  Println(Factorial(6));
end.
