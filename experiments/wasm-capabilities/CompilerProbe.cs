using System.Diagnostics;
using System.Net.Http.Json;
using System.Reflection;
using System.Text.Json;
using Languages.Pascal;
using PascalABCCompiler;
using PascalABCCompiler.Errors;
using PascalABCCompiler.NetHelper;

namespace wasm_capabilities;

internal static class CompilerProbe
{
    private const string Root = "/pabc";

    public static async Task<string> RunAsync(HttpClient httpClient)
    {
        var report = new Dictionary<string, object?>
        {
            ["success"] = false,
            ["stdout"] = "",
            ["stderr"] = "",
            ["diagnostics"] = Array.Empty<object>()
        };

        try
        {
            var initialization = Stopwatch.StartNew();
            await StageAssetsAsync(httpClient);
            Environment.CurrentDirectory = Path.Combine(Root, "runtime");
            NetCoreSystemReferences.RuntimeDirectoryOverride = Path.Combine(Root, "runtime");
            PascalLanguageRegistration.RegisterPascalLanguage();
            initialization.Stop();

            var workDirectory = Path.Combine(Root, "work");
            Directory.CreateDirectory(workDirectory);
            var sourcePath = Path.Combine(workDirectory, "program.pas");
            File.WriteAllText(sourcePath, """
                begin
                  System.AppDomain.CurrentDomain.SetData('PascalABC.Web.probe', 'ran');
                  var a := ReadInteger;
                  var b := ReadInteger;
                  Println(a + b);
                end.
                """);

            var compiler = new Compiler();
            var options = new CompilerOptions(sourcePath, CompilerOptions.OutputType.ConsoleApplicaton)
            {
                Debug = false,
                Rebuild = false,
                SavePCU = false,
                SaveDocumentation = false,
                OutputDirectory = workDirectory,
                SystemDirectory = Root,
                SearchDirectories = new List<string>(),
                StandardDirectories = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                {
                    ["%PABCSYSTEM%"] = Root
                }
            };

            var compilation = Stopwatch.StartNew();
            var outputPath = compiler.Compile(options);
            compilation.Stop();

            report["version"] = Compiler.Version;
            report["initTime"] = initialization.Elapsed.TotalMilliseconds;
            report["compileTime"] = compilation.Elapsed.TotalMilliseconds;
            report["outputPath"] = outputPath;
            report["diagnostics"] = compiler.ErrorsList.Select(ToDiagnostic).ToArray();

            if (outputPath is null || compiler.ErrorsList.Count != 0)
                return Serialize(report);

            var programBytes = File.ReadAllBytes(outputPath);
            report["assemblyBytes"] = programBytes.Length;
            using var input = new StringReader("20\n22\n");
            using var output = new StringWriter();
            using var error = new StringWriter();
            var execution = Stopwatch.StartNew();
            try
            {
                AppDomain.CurrentDomain.SetData("PascalABC.Web.stdin", input);
                AppDomain.CurrentDomain.SetData("PascalABC.Web.stdout", output);
                var studentAssembly = Assembly.Load(programBytes);
                var entryPoint = studentAssembly.EntryPoint
                    ?? throw new InvalidOperationException("Generated assembly has no entry point.");
                report["entryPoint"] = $"{entryPoint.DeclaringType?.FullName}.{entryPoint.Name}";
                if (entryPoint.GetParameters().Length == 0 && entryPoint.ReturnType == typeof(void))
                    entryPoint.CreateDelegate<Action>()();
                else
                    entryPoint.Invoke(null, new object?[] { Array.Empty<string>() });
                report["probe"] = AppDomain.CurrentDomain.GetData("PascalABC.Web.probe");
                report["exitCode"] = 0;
            }
            catch (TargetInvocationException exception)
            {
                report["exitCode"] = 1;
                error.Write(exception.InnerException ?? exception);
            }
            finally
            {
                execution.Stop();
                AppDomain.CurrentDomain.SetData("PascalABC.Web.stdin", null);
                AppDomain.CurrentDomain.SetData("PascalABC.Web.stdout", null);
                AppDomain.CurrentDomain.SetData("PascalABC.Web.probe", null);
            }

            report["executionTime"] = execution.Elapsed.TotalMilliseconds;
            report["stdout"] = output.ToString();
            report["stderr"] = error.ToString();
            report["success"] = (int)report["exitCode"]! == 0;
        }
        catch (Exception exception)
        {
            report["fatal"] = exception.ToString();
        }

        return Serialize(report);
    }

    private static async Task StageAssetsAsync(HttpClient httpClient)
    {
        var manifest = await httpClient.GetFromJsonAsync<string[]>("pabc-assets/manifest.json")
            ?? throw new InvalidOperationException("PascalABC asset manifest is empty.");
        using var gate = new SemaphoreSlim(8);
        await Task.WhenAll(manifest.Select(async asset =>
        {
            await gate.WaitAsync();
            try
            {
                var bytes = await httpClient.GetByteArrayAsync($"pabc-assets/{asset}");
                var path = Path.Combine(Root, asset.Replace('/', Path.DirectorySeparatorChar));
                Directory.CreateDirectory(Path.GetDirectoryName(path)!);
                File.WriteAllBytes(path, bytes);
            }
            finally
            {
                gate.Release();
            }
        }));
    }

    private static object ToDiagnostic(Error error)
    {
        var location = (error as LocatedError)?.SourceLocation;
        return new
        {
            line = location?.BeginPosition.Line ?? 0,
            column = location?.BeginPosition.Column ?? 0,
            severity = "error",
            code = error.GetType().Name,
            message = error.Message
        };
    }

    private static string Serialize(object value) =>
        JsonSerializer.Serialize(value, new JsonSerializerOptions { WriteIndented = true });
}
