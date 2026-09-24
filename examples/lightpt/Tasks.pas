unit Tasks;

{$savepcu false}

uses LightPT;

procedure CheckTaskT(name: string);
begin
  case name of
    'CountDivisibleByFour': CheckOutput(3);
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
