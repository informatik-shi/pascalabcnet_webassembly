// Browser compatibility implementation of the PascalABC.NET LightPT module.
// It keeps the educational IO/checking API, but deliberately excludes desktop
// files, credentials, System.Management and remote database submission.
unit LightPT;

interface

type
  MessageColorT = (MsgColorGreen, MsgColorRed, MsgColorOrange, MsgColorMagenta, MsgColorGray);
  TaskStatus = (NotUnderControl, Solved, IOError, BadSolution, PartialSolution, InitialTask, BadInitialTask, InitialTaskPT4, ErrFix, Demo);

  ObjectList = class
  private
    lst := new List<object>;
  public
    static function New: ObjectList := new ObjectList;
    procedure Add(value: object) := lst.Add(value);
    function AddRange(values: sequence of integer): ObjectList;
    function AddRange(values: sequence of real): ObjectList;
    function AddRange(values: sequence of string): ObjectList;
    function AddRange(values: sequence of char): ObjectList;
    function AddRange(values: sequence of boolean): ObjectList;
    function AddRange(values: sequence of object): ObjectList;
    function AddFill(count: integer; value: object): ObjectList;
    function AddArithm(count, first, step: integer): ObjectList;
    function AddArithm(count: integer; first, step: real): ObjectList;
    function AddFib(count: integer): ObjectList;
    function AddGeom(count, first, factor: integer): ObjectList;
    function AddGeom(count: integer; first, factor: real): ObjectList;
    function ToArray: array of object := lst.ToArray;
  end;

  EmptyType = (Empty);

var
  TaskResult: TaskStatus := NotUnderControl;
  OutputString := new StringBuilder;
  OutputList := new List<object>;
  InputList := new List<object>;
  InitialOutputList := new List<System.Type>;
  InitialInputList := new List<System.Type>;
  CheckTask: procedure(name: string);
  TaskName := '';
  Silent := false;

function Random(a, b: integer): integer;
function Random(n: integer): integer;
function Random: real;
function Random(a, b: real): real;
function RandomReal(a, b: real; digits: integer := 1): real;
function Random(a, b: char): char;
function Random(diap: IntRange): integer;
function Random(diap: RealRange): real;
function Random(diap: CharRange): char;

function Random2(a, b: integer): (integer, integer);
function Random2(a, b: real): (real, real);
function Random2(a, b: char): (char, char);
function Random3(a, b: integer): (integer, integer, integer);
function Random3(a, b: real): (real, real, real);
function Random3(a, b: char): (char, char, char);

function ArrRandomInteger(n: integer; a, b: integer): array of integer;
function ArrRandomInteger(n: integer): array of integer;
function ArrRandomReal(n: integer; a, b: real; digits: integer := 1): array of real;
function ArrRandomReal(n: integer; digits: integer := 1): array of real;
function MatrRandomInteger(m, n, a, b: integer): array [,] of integer;
function MatrRandomInteger(m, n: integer): array [,] of integer;
function MatrRandomReal(m, n: integer; a, b: real; digits: integer := 2): array [,] of real;
function MatrRandomReal(m, n: integer): array [,] of real;

function ReadInteger(prompt: string): integer;
function ReadlnInteger(prompt: string): integer;
function ReadInteger2(prompt: string): (integer, integer);
function ReadlnInteger2(prompt: string): (integer, integer);
function ReadInteger3(prompt: string): (integer, integer, integer);
function ReadlnInteger3(prompt: string): (integer, integer, integer);
function ReadReal(prompt: string): real;
function ReadlnReal(prompt: string): real;
function ReadReal2(prompt: string): (real, real);
function ReadlnReal2(prompt: string): (real, real);
function ReadChar(prompt: string): char;
function ReadlnChar(prompt: string): char;
function ReadString(prompt: string): string;
function ReadlnString(prompt: string): string;

procedure Print(params args: array of object);
procedure Println(params args: array of object);
procedure Print(value: object);
procedure Print(value: string);
procedure Print(value: char);

procedure ColoredMessage(message: string; color: MessageColorT);
procedure ColoredMessage(message: string);

function ToObjArray(values: sequence of integer): array of object;
function ToObjArray(values: sequence of real): array of object;
function ToObjArray(values: sequence of string): array of object;
function ToObjArray(values: sequence of char): array of object;
function ToObjArray(values: sequence of boolean): array of object;

function CompareValues(left, right: object): boolean;
function CompareValuesWithOutput(params expected: array of object): boolean;
procedure CheckOutput(params expected: array of object);
procedure CheckOutputSilent(params expected: array of object);
procedure CheckOutput(expected: ObjectList);
procedure CheckOutputSilent(expected: ObjectList);
procedure CheckOutputSeq(values: sequence of integer);
procedure CheckOutputSeq(values: sequence of real);
procedure CheckOutputSeq(values: sequence of string);
procedure CheckOutputSeq(values: sequence of char);
procedure CheckOutputSeq(values: sequence of boolean);
procedure CheckOutputSeq(values: sequence of object);
procedure CheckOutputSeq(values: ObjectList);
procedure CheckOutputString(expected: string);

procedure CheckInput(types: array of System.Type);
procedure CheckInputTypes(types: array of System.Type);
procedure CheckInputIsEmpty;
procedure CheckInputCount(count: integer);
procedure CheckOutput2Count(count: integer);
procedure CheckData(InitialInput: array of System.Type := nil;
  InitialOutput: array of System.Type := nil; Input: array of System.Type := nil);

function cInt: System.Type;
function cRe: System.Type;
function cStr: System.Type;
function cBool: System.Type;
function cChar: System.Type;

function Int(index: integer): integer;
function Re(index: integer): real;
function Str(index: integer): string;
function Boo(index: integer): boolean;
function Chr(index: integer): char;
function OutInt(index: integer): integer;
function OutRe(index: integer): real;
function OutStr(index: integer): string;
function OutBoo(index: integer): boolean;
function OutChr(index: integer): char;
function IntArr(count: integer): array of integer;
function ReArr(count: integer): array of real;

procedure ConvertStringsToNumbersInOutputList;
procedure FlattenOutput;
procedure ClearOutputListFromSpaces;
procedure ClearOutputListFromEmptyStrings;
procedure FilterOnlyNumbers;
procedure FilterOnlyNumbersAndBools;
procedure ClearLists;
procedure SetMessagesOn;
procedure SetMessageOff;

implementation

var
  CaptureOutput := true;
  AdditionalMessages := false;
  PreviousIOSystem: IOSystem;

type
  BrowserLightIOSystem = class(IOStandardSystem)
  public
    procedure write(value: object); override;
    procedure writeln; override;
    function ReadLine: string; override;
    procedure read(var value: integer); override;
    procedure read(var value: real); override;
    procedure read(var value: char); override;
    procedure read(var value: string); override;
    procedure read(var value: byte); override;
    procedure read(var value: shortint); override;
    procedure read(var value: smallint); override;
    procedure read(var value: word); override;
    procedure read(var value: longword); override;
    procedure read(var value: int64); override;
    procedure read(var value: uint64); override;
    procedure read(var value: single); override;
    procedure read(var value: boolean); override;
    procedure read(var value: BigInteger); override;
  end;

procedure BrowserLightIOSystem.write(value: object);
begin
  inherited write(value);
  if CaptureOutput then
  begin
    OutputString.Append(ObjectToString(value));
    OutputList.Add(value);
  end;
end;

procedure BrowserLightIOSystem.writeln;
begin
  inherited writeln;
  if CaptureOutput then OutputString.Append(NewLine);
end;

function BrowserLightIOSystem.ReadLine: string;
begin
  Result := inherited ReadLine;
  InputList.Add(Result);
end;

procedure BrowserLightIOSystem.read(var value: integer); begin inherited read(value); InputList.Add(value); end;
procedure BrowserLightIOSystem.read(var value: real); begin inherited read(value); InputList.Add(value); end;
procedure BrowserLightIOSystem.read(var value: char); begin inherited read(value); InputList.Add(value); end;
procedure BrowserLightIOSystem.read(var value: string); begin inherited read(value); InputList.Add(value); end;
procedure BrowserLightIOSystem.read(var value: byte); begin inherited read(value); InputList.Add(value); end;
procedure BrowserLightIOSystem.read(var value: shortint); begin inherited read(value); InputList.Add(value); end;
procedure BrowserLightIOSystem.read(var value: smallint); begin inherited read(value); InputList.Add(value); end;
procedure BrowserLightIOSystem.read(var value: word); begin inherited read(value); InputList.Add(value); end;
procedure BrowserLightIOSystem.read(var value: longword); begin inherited read(value); InputList.Add(value); end;
procedure BrowserLightIOSystem.read(var value: int64); begin inherited read(value); InputList.Add(value); end;
procedure BrowserLightIOSystem.read(var value: uint64); begin inherited read(value); InputList.Add(value); end;
procedure BrowserLightIOSystem.read(var value: single); begin inherited read(value); InputList.Add(value); end;
procedure BrowserLightIOSystem.read(var value: boolean); begin inherited read(value); InputList.Add(value); end;
procedure BrowserLightIOSystem.read(var value: BigInteger); begin inherited read(value); InputList.Add(value); end;

function ObjectList.AddRange(values: sequence of integer): ObjectList; begin lst.AddRange(values.Select(x -> object(x))); Result := Self; end;
function ObjectList.AddRange(values: sequence of real): ObjectList; begin lst.AddRange(values.Select(x -> object(x))); Result := Self; end;
function ObjectList.AddRange(values: sequence of string): ObjectList; begin lst.AddRange(values.Select(x -> object(x))); Result := Self; end;
function ObjectList.AddRange(values: sequence of char): ObjectList; begin lst.AddRange(values.Select(x -> object(x))); Result := Self; end;
function ObjectList.AddRange(values: sequence of boolean): ObjectList; begin lst.AddRange(values.Select(x -> object(x))); Result := Self; end;
function ObjectList.AddRange(values: sequence of object): ObjectList; begin lst.AddRange(values); Result := Self; end;
function ObjectList.AddFill(count: integer; value: object): ObjectList := AddRange(ArrFill(count, value));
function ObjectList.AddArithm(count, first, step: integer): ObjectList := AddRange(ArrGen(count, first, x -> x + step));
function ObjectList.AddArithm(count: integer; first, step: real): ObjectList := AddRange(ArrGen(count, first, x -> x + step));
function ObjectList.AddFib(count: integer): ObjectList := AddRange(ArrGen(count, 1, 1, (x, y) -> x + y));
function ObjectList.AddGeom(count, first, factor: integer): ObjectList := AddRange(ArrGen(count, first, x -> x * factor));
function ObjectList.AddGeom(count: integer; first, factor: real): ObjectList := AddRange(ArrGen(count, first, x -> x * factor));

procedure RememberInput(value: object) := InputList.Add(value);

function Random(a, b: integer): integer; begin Result := PABCSystem.Random(a, b); RememberInput(Result); end;
function Random(n: integer): integer; begin Result := PABCSystem.Random(n); RememberInput(Result); end;
function Random: real; begin Result := PABCSystem.Random; RememberInput(Result); end;
function Random(a, b: real): real; begin Result := PABCSystem.Random(a, b); RememberInput(Result); end;
function RandomReal(a, b: real; digits: integer): real; begin Result := PABCSystem.RandomReal(a, b, digits); RememberInput(Result); end;
function Random(a, b: char): char; begin Result := PABCSystem.Random(a, b); RememberInput(Result); end;
function Random(diap: IntRange): integer; begin Result := PABCSystem.Random(diap); RememberInput(Result); end;
function Random(diap: RealRange): real; begin Result := PABCSystem.Random(diap); RememberInput(Result); end;
function Random(diap: CharRange): char; begin Result := PABCSystem.Random(diap); RememberInput(Result); end;

function Random2(a, b: integer): (integer, integer) := (Random(a, b), Random(a, b));
function Random2(a, b: real): (real, real) := (Random(a, b), Random(a, b));
function Random2(a, b: char): (char, char) := (Random(a, b), Random(a, b));
function Random3(a, b: integer): (integer, integer, integer) := (Random(a, b), Random(a, b), Random(a, b));
function Random3(a, b: real): (real, real, real) := (Random(a, b), Random(a, b), Random(a, b));
function Random3(a, b: char): (char, char, char) := (Random(a, b), Random(a, b), Random(a, b));

function ArrRandomInteger(n: integer; a, b: integer): array of integer;
begin Result := ArrGen(n, i -> Random(a, b)); end;
function ArrRandomInteger(n: integer): array of integer := ArrRandomInteger(n, 0, 100);
function ArrRandomReal(n: integer; a, b: real; digits: integer): array of real;
begin Result := ArrGen(n, i -> RandomReal(a, b, digits)); end;
function ArrRandomReal(n: integer; digits: integer): array of real := ArrRandomReal(n, 0.0, 10.0, digits);

function MatrRandomInteger(m, n, a, b: integer): array [,] of integer;
begin
  Result := new integer[m, n];
  for var i := 0 to m - 1 do for var j := 0 to n - 1 do Result[i, j] := Random(a, b);
end;
function MatrRandomInteger(m, n: integer): array [,] of integer := MatrRandomInteger(m, n, 0, 100);
function MatrRandomReal(m, n: integer; a, b: real; digits: integer): array [,] of real;
begin
  Result := new real[m, n];
  for var i := 0 to m - 1 do for var j := 0 to n - 1 do Result[i, j] := RandomReal(a, b, digits);
end;
function MatrRandomReal(m, n: integer): array [,] of real := MatrRandomReal(m, n, 0.0, 10.0, 2);

function ReadInteger(prompt: string): integer := PABCSystem.ReadInteger(prompt);
function ReadlnInteger(prompt: string): integer := PABCSystem.ReadlnInteger(prompt);
function ReadInteger2(prompt: string): (integer, integer) := (ReadInteger(prompt), PABCSystem.ReadInteger);
function ReadlnInteger2(prompt: string): (integer, integer) := ReadInteger2(prompt);
function ReadInteger3(prompt: string): (integer, integer, integer) := (ReadInteger(prompt), PABCSystem.ReadInteger, PABCSystem.ReadInteger);
function ReadlnInteger3(prompt: string): (integer, integer, integer) := ReadInteger3(prompt);
function ReadReal(prompt: string): real := PABCSystem.ReadReal(prompt);
function ReadlnReal(prompt: string): real := PABCSystem.ReadlnReal(prompt);
function ReadReal2(prompt: string): (real, real) := (ReadReal(prompt), PABCSystem.ReadReal);
function ReadlnReal2(prompt: string): (real, real) := ReadReal2(prompt);
function ReadChar(prompt: string): char := PABCSystem.ReadChar(prompt);
function ReadlnChar(prompt: string): char := PABCSystem.ReadlnChar(prompt);
function ReadString(prompt: string): string := PABCSystem.ReadString(prompt);
function ReadlnString(prompt: string): string := PABCSystem.ReadlnString(prompt);

procedure Print(params args: array of object) := PABCSystem.Print(args);
procedure Println(params args: array of object) := PABCSystem.Println(args);
procedure Print(value: object) := PABCSystem.Print(value);
procedure Print(value: string) := PABCSystem.Print(value);
procedure Print(value: char) := PABCSystem.Print(object(value));

procedure ColoredMessage(message: string; color: MessageColorT);
begin
  if Silent then exit;
  var previous := CaptureOutput;
  CaptureOutput := false;
  PABCSystem.Println(message);
  CaptureOutput := previous;
end;
procedure ColoredMessage(message: string) := ColoredMessage(message, MsgColorRed);

function ToObjArray(values: sequence of integer): array of object := values.Select(x -> object(x)).ToArray;
function ToObjArray(values: sequence of real): array of object := values.Select(x -> object(x)).ToArray;
function ToObjArray(values: sequence of string): array of object := values.Select(x -> object(x)).ToArray;
function ToObjArray(values: sequence of char): array of object := values.Select(x -> object(x)).ToArray;
function ToObjArray(values: sequence of boolean): array of object := values.Select(x -> object(x)).ToArray;

function IsNumber(value: object): boolean :=
  (value is byte) or (value is shortint) or (value is smallint) or (value is word) or
  (value is integer) or (value is longword) or (value is int64) or (value is uint64) or
  (value is single) or (value is real) or (value is decimal);

function CompareValues(left, right: object): boolean;
begin
  if object.ReferenceEquals(left, right) then exit(true);
  if (left = nil) or (right = nil) then exit(false);
  if IsNumber(left) and IsNumber(right) then
    exit(Abs(System.Convert.ToDouble(left) - System.Convert.ToDouble(right)) < 0.000001);
  Result := left.Equals(right);
end;

function IsOnlySpaces(value: object): boolean :=
  (value is string) and string(value).All(ch -> char.IsWhiteSpace(ch));

function ActualOutput: array of object := OutputList.Where(value -> not IsOnlySpaces(value)).ToArray;

function CompareArrays(expected, actual: array of object): boolean;
begin
  if expected.Length <> actual.Length then exit(false);
  for var i := 0 to expected.Length - 1 do
    if not CompareValues(expected[i], actual[i]) then exit(false);
  Result := true;
end;

function CompareValuesWithOutput(params expected: array of object): boolean := CompareArrays(expected, ActualOutput);

function ValueText(value: object): string := if value = nil then 'nil' else ObjectToString(value);
function ValuesText(values: array of object): string := values.Select(ValueText).JoinToString(', ');

procedure ReportCheck(expected: array of object; showMessage: boolean);
begin
  var actual := ActualOutput;
  if CompareArrays(expected, actual) then
  begin
    TaskResult := Solved;
    if showMessage then ColoredMessage('✓ LightPT: задание выполнено', MsgColorGreen);
  end
  else
  begin
    TaskResult := BadSolution;
    if showMessage then
      // The expected values live only in hidden Tasks.pas and must not be
      // disclosed to the student through stdout.
      ColoredMessage('✗ LightPT: неверное решение', MsgColorRed);
  end;
end;

procedure CheckOutput(params expected: array of object) := ReportCheck(expected, true);
procedure CheckOutputSilent(params expected: array of object) := ReportCheck(expected, false);
procedure CheckOutput(expected: ObjectList) := CheckOutput(expected.ToArray);
procedure CheckOutputSilent(expected: ObjectList) := CheckOutputSilent(expected.ToArray);
procedure CheckOutputSeq(values: sequence of integer) := CheckOutput(ToObjArray(values));
procedure CheckOutputSeq(values: sequence of real) := CheckOutput(ToObjArray(values));
procedure CheckOutputSeq(values: sequence of string) := CheckOutput(ToObjArray(values));
procedure CheckOutputSeq(values: sequence of char) := CheckOutput(ToObjArray(values));
procedure CheckOutputSeq(values: sequence of boolean) := CheckOutput(ToObjArray(values));
procedure CheckOutputSeq(values: sequence of object) := CheckOutput(values.ToArray);
procedure CheckOutputSeq(values: ObjectList) := CheckOutput(values);

procedure CheckOutputString(expected: string);
begin
  if OutputString.ToString.TrimEnd = expected.TrimEnd then
  begin TaskResult := Solved; ColoredMessage('✓ LightPT: задание выполнено', MsgColorGreen); end
  else
  begin TaskResult := BadSolution; ColoredMessage('✗ LightPT: неверный текстовый вывод', MsgColorRed); end;
end;

procedure CheckInputTypes(types: array of System.Type);
begin
  if types = nil then exit;
  if types.Length <> InputList.Count then
  begin TaskResult := BadSolution; ColoredMessage($'✗ LightPT: введено значений {InputList.Count}, ожидалось {types.Length}'); exit; end;
  for var i := 0 to types.Length - 1 do
    if InputList[i].GetType <> types[i] then
    begin TaskResult := BadSolution; ColoredMessage($'✗ LightPT: неверный тип входного значения №{i + 1}'); exit; end;
end;
procedure CheckInput(types: array of System.Type) := CheckInputTypes(types);
procedure CheckInputIsEmpty := CheckInputTypes(new System.Type[0]);
procedure CheckInputCount(count: integer);
begin if InputList.Count <> count then begin TaskResult := BadSolution; ColoredMessage($'✗ LightPT: введено значений {InputList.Count}, ожидалось {count}'); end; end;
procedure CheckOutput2Count(count: integer);
begin if ActualOutput.Length < count then begin TaskResult := BadSolution; ColoredMessage($'✗ LightPT: выведено значений {ActualOutput.Length}, ожидалось не менее {count}'); end; end;

procedure CheckData(InitialInput, InitialOutput, Input: array of System.Type);
begin
  InitialInputList.Clear; InitialOutputList.Clear;
  if InitialInput <> nil then InitialInputList.AddRange(InitialInput);
  if InitialOutput <> nil then InitialOutputList.AddRange(InitialOutput);
  if Input <> nil then CheckInputTypes(Input);
end;

function cInt: System.Type := typeof(integer);
function cRe: System.Type := typeof(real);
function cStr: System.Type := typeof(string);
function cBool: System.Type := typeof(boolean);
function cChar: System.Type := typeof(char);

function Int(index: integer): integer := integer(InputList[index]);
function Re(index: integer): real := System.Convert.ToDouble(InputList[index]);
function Str(index: integer): string := string(InputList[index]);
function Boo(index: integer): boolean := boolean(InputList[index]);
function Chr(index: integer): char := char(InputList[index]);
function OutInt(index: integer): integer := integer(ActualOutput[index]);
function OutRe(index: integer): real := System.Convert.ToDouble(ActualOutput[index]);
function OutStr(index: integer): string := string(ActualOutput[index]);
function OutBoo(index: integer): boolean := boolean(ActualOutput[index]);
function OutChr(index: integer): char := char(ActualOutput[index]);
function IntArr(count: integer): array of integer := (0..count - 1).Select(i -> Int(i)).ToArray;
function ReArr(count: integer): array of real := (0..count - 1).Select(i -> Re(i)).ToArray;

procedure ConvertStringsToNumbersInOutputList;
begin
  for var i := 0 to OutputList.Count - 1 do
    if OutputList[i] is string then
    begin
      var text := string(OutputList[i]);
      var intValue: integer;
      var realValue: real;
      if integer.TryParse(text, intValue) then OutputList[i] := intValue
      else if real.TryParse(text, realValue) then OutputList[i] := realValue;
    end;
end;

procedure FlattenOutput;
begin
  var flattened := new List<object>;
  foreach var value in OutputList do
    if (value is System.Collections.IEnumerable) and not (value is string) then
      foreach var item in System.Collections.IEnumerable(value) do flattened.Add(item)
    else flattened.Add(value);
  OutputList.Clear;
  OutputList.AddRange(flattened);
end;

procedure ClearOutputListFromSpaces;
begin
  var values := OutputList.Where(value -> not IsOnlySpaces(value)).ToArray;
  OutputList.Clear; OutputList.AddRange(values);
end;
procedure ClearOutputListFromEmptyStrings;
begin
  var values := OutputList.Where(value -> not ((value is string) and string.IsNullOrWhiteSpace(string(value)))).ToArray;
  OutputList.Clear; OutputList.AddRange(values);
end;
procedure FilterOnlyNumbers;
begin
  var values := OutputList.Where(IsNumber).ToArray;
  OutputList.Clear; OutputList.AddRange(values);
end;
procedure FilterOnlyNumbersAndBools;
begin
  var values := OutputList.Where(value -> IsNumber(value) or (value is boolean)).ToArray;
  OutputList.Clear; OutputList.AddRange(values);
end;
procedure ClearLists;
begin InputList.Clear; OutputList.Clear; OutputString.Clear; TaskResult := NotUnderControl; end;
procedure SetMessagesOn := AdditionalMessages := true;
procedure SetMessageOff := AdditionalMessages := false;

initialization
  var configuredTaskName := System.AppDomain.CurrentDomain.GetData('PascalABC.Web.lightpt.taskName');
  if configuredTaskName <> nil then
    TaskName := configuredTaskName.ToString;
  PreviousIOSystem := CurrentIOSystem;
  CurrentIOSystem := new BrowserLightIOSystem;
finalization
  try
    if CheckTask <> nil then CheckTask(TaskName);
  except
    on error: Exception do
    begin
      TaskResult := IOError;
      // Do not expose hidden checker details or expected values.
      ColoredMessage('✗ LightPT: ошибка скрытой проверки', MsgColorRed);
    end;
  end;
  System.AppDomain.CurrentDomain.SetData('PascalABC.Web.lightpt.result', TaskResult.ToString);
  CurrentIOSystem := PreviousIOSystem;
end.
