# LightPT в браузере

`LightPT` подключается сайтом автоматически. Код ученика и скрытая проверка хранятся в разных Pascal-файлах: ученик не пишет `uses LightPT`, не подключает `Tasks` и не вызывает `CheckOutput`.

## Файл программы ученика

`Program.pas`:

```pascal
begin
  var values := Arr(3, 8, 12, 5, 16);
  var divisibleByFour := values.Count(value -> value mod 4 = 0);
  Println(divisibleByFour);
end.
```

## Скрытый файл проверки

`Tasks.pas`:

```pascal
unit Tasks;

{$savepcu false}

uses LightPT;

procedure CheckTaskT(name: string);
begin
  case name of
    'CountDivisibleByFour': CheckOutput(3);
  end;
end;

initialization
  CheckTask := CheckTaskT;
end.
```

Сайт загружает оба файла отдельно, но передаёт в редактор только `Program.pas`:

```js
const [program, tasks] = await Promise.all([
  fetch("./Program.pas").then(response => response.text()),
  fetch("./Tasks.pas").then(response => response.text())
]);

const result = await PascalABC.run(program, {
  lightPT: {
    tasks,
    taskName: "CountDivisibleByFour"
  }
});

console.log(result.lightPT);
// { checked: true, taskName: "CountDivisibleByFour", status: "Solved", passed: true }
```

Во время компиляции Web host создаёт изолированный каталог с `Program.pas`, скрытым `Tasks.pas` и служебным `lightpt.dat`. Штатный `TeacherControlConverter` PascalABC.NET автоматически добавляет `LightPT` и `Tasks` в синтаксическое дерево. Исходный текст программы ученика при этом не изменяется.

Проверка выполняется в финализации `LightPT`, после завершения основной программы. Ожидаемые значения не включаются в stdout и не возвращаются в результате API. Возвращается только итоговый статус.

## Поддерживаемый subset

- перехват стандартных `Read*`, `Write`, `Print` и `Println`;
- `InputList`, `OutputList`, `OutputString` и `ObjectList`;
- `CheckOutput`, `CheckOutputSeq`, `CheckOutputString` внутри `Tasks.pas`;
- базовые `CheckInput`, `CheckInputCount`, `CheckData`;
- `cInt`, `cRe`, `cStr`, `cBool`, `cChar`;
- `Random`, `Random2`, `Random3`, `ArrRandom*`, `MatrRandom*` с запоминанием входных данных;
- фильтрация и преобразование списка вывода.

Desktop-функции оригинального LightPT не переносятся: чтение настроек и авторизации, `System.Management`, локальная база `db.txt` и отправка результата на удалённый сервер. Интеграцию с журналом преподавателя следует выполнять через API сайта.

Важно: файл, отправленный в браузер, технически нельзя считать секретным от пользователя с DevTools. Для экзаменационных тестов, которые должны быть криптографически скрыты, проверку следует выполнять на сервере. Данная реализация скрывает `Tasks.pas` от редактора и ученической программы и воспроизводит модель LightPT на клиенте.
