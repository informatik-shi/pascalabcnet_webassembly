unit Tasks;

{$savepcu false}

uses LightPT;

// Эталонный решатель доступен только преподавательской проверке.
function ReferenceSolve(values: sequence of integer): integer :=
  values.Count(value -> value mod 4 = 0);

procedure CheckCountDivisibleByFour;
begin
  // Первый элемент ввода — длина массива, остальные — его элементы.
  if InputList.Count = 0 then
  begin
    TaskResult := BadSolution;
    ColoredMessage('✗ LightPT: программа не прочитала входные данные');
    exit;
  end;

  var count := Int(0);
  CheckInputCount(count + 1);
  if TaskResult = BadSolution then exit;

  var values := ArrGen(count, i -> Int(i + 1));
  CheckOutput(ReferenceSolve(values));
end;

procedure CheckTaskT(name: string);
begin
  case name of
    'CountDivisibleByFour': CheckCountDivisibleByFour;
    else
    begin
      TaskResult := BadSolution;
      ColoredMessage('✗ LightPT: неизвестное задание');
    end;
  end;
end;

initialization
  CheckTask := CheckTaskT;
end.
