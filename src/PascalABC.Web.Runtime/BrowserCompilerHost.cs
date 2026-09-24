using System.Diagnostics;
using System.Net.Http.Json;
using System.Reflection;
using System.Runtime.InteropServices.JavaScript;
using System.Text.Json;
using System.Text.Json.Serialization;
using Languages.Pascal;
using PascalABCCompiler;
using PascalABCCompiler.Errors;
using PascalABCCompiler.NetHelper;
using PascalABC.Web.Graphics;

namespace PascalABC.Web.Runtime;

public static partial class BrowserCompilerHost
{
    private const string Root = "/pabc";
    private const string RuntimeDirectory = Root + "/runtime";
    private const string WorkDirectory = Root + "/work";
    private const string StdinKey = "PascalABC.Web.stdin";
    private const string StdoutKey = "PascalABC.Web.stdout";
    private const string LightPTTaskNameKey = "PascalABC.Web.lightpt.taskName";
    private const string LightPTResultKey = "PascalABC.Web.lightpt.result";

    private static readonly SemaphoreSlim OperationGate = new(1, 1);
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
    };
    private static readonly Dictionary<string, CompiledProgram> Artifacts = new();
    private static readonly Queue<string> ArtifactOrder = new();
    private static bool initialized;
    private static int nextProgramId;

    [JSExport]
    public static async Task<string> Invoke(string requestJson)
    {
        await OperationGate.WaitAsync();
        try
        {
            var request = JsonSerializer.Deserialize<RuntimeRequest>(requestJson, JsonOptions)
                ?? throw new ArgumentException("The runtime request is empty.");

            if (!string.Equals(request.Operation, "version", StringComparison.OrdinalIgnoreCase))
                await EnsureInitializedAsync(request.BaseUrl);

            object response = request.Operation?.ToLowerInvariant() switch
            {
                "init" => new
                {
                    success = true,
                    version = Compiler.Version,
                    runtime = Environment.Version.ToString()
                },
                "version" => new
                {
                    success = true,
                    version = Compiler.Version,
                    runtime = Environment.Version.ToString()
                },
                "compile" => CompileForApi(request.Code ?? string.Empty, request.LightPT),
                "run" => RunForApi(request.Code ?? string.Empty, request.Stdin ?? string.Empty, request.LightPT),
                "execute" => ExecuteForApi(request.ArtifactId, request.Stdin ?? string.Empty),
                "check" => CheckForApi(request),
                _ => throw new ArgumentException($"Unknown operation '{request.Operation}'.")
            };

            return JsonSerializer.Serialize(response, JsonOptions);
        }
        catch (Exception exception)
        {
            return JsonSerializer.Serialize(new
            {
                success = false,
                stdout = string.Empty,
                stderr = exception.ToString(),
                exitCode = 1,
                diagnostics = Array.Empty<object>()
            }, JsonOptions);
        }
        finally
        {
            OperationGate.Release();
        }
    }

    private static async Task EnsureInitializedAsync(string? baseUrl)
    {
        if (initialized)
            return;
        if (string.IsNullOrWhiteSpace(baseUrl))
            throw new ArgumentException("baseUrl is required for the first runtime request.");

        using var httpClient = new HttpClient { BaseAddress = new Uri(baseUrl, UriKind.Absolute) };
        var manifest = await httpClient.GetFromJsonAsync<string[]>("pabc-assets/manifest.json")
            ?? throw new InvalidOperationException("PascalABC.NET asset manifest is empty.");

        using var downloadGate = new SemaphoreSlim(8);
        await Task.WhenAll(manifest.Select(async asset =>
        {
            await downloadGate.WaitAsync();
            try
            {
                var bytes = await httpClient.GetByteArrayAsync("pabc-assets/" + asset);
                var path = Path.Combine(Root, asset.Replace('/', Path.DirectorySeparatorChar));
                Directory.CreateDirectory(Path.GetDirectoryName(path)!);
                await File.WriteAllBytesAsync(path, bytes);
            }
            finally
            {
                downloadGate.Release();
            }
        }));

        Directory.CreateDirectory(WorkDirectory);
        Environment.CurrentDirectory = RuntimeDirectory;
        NetCoreSystemReferences.RuntimeDirectoryOverride = RuntimeDirectory;
        PascalLanguageRegistration.RegisterPascalLanguage();
        initialized = true;
    }

    private static object CompileForApi(string code, LightPTConfiguration? lightPT)
    {
        var compilation = Compile(code, lightPT);
        if (!compilation.Success)
            return CompilationResponse(compilation);

        Artifacts[compilation.ArtifactId] = compilation;
        ArtifactOrder.Enqueue(compilation.ArtifactId);
        while (ArtifactOrder.Count > 16)
            Artifacts.Remove(ArtifactOrder.Dequeue());

        return CompilationResponse(compilation);
    }

    private static object RunForApi(string code, string stdin, LightPTConfiguration? lightPT)
    {
        var compilation = Compile(code, lightPT);
        if (!compilation.Success)
            return CompilationResponse(compilation);

        var execution = Execute(compilation, stdin);
        return new
        {
            success = execution.ExitCode == 0,
            execution.Stdout,
            execution.Stderr,
            execution.ExitCode,
            compilation.CompileTime,
            execution.ExecutionTime,
            compilation.Diagnostics,
            compilation.ArtifactId,
            assemblyBytes = compilation.AssemblyBytes!.Length,
            execution.LightPT
        };
    }

    private static object ExecuteForApi(string? artifactId, string stdin)
    {
        if (string.IsNullOrWhiteSpace(artifactId) || !Artifacts.TryGetValue(artifactId, out var compilation))
            throw new ArgumentException($"Unknown or expired artifact '{artifactId}'.");

        var execution = Execute(compilation, stdin);
        return new
        {
            success = execution.ExitCode == 0,
            execution.Stdout,
            execution.Stderr,
            execution.ExitCode,
            compilation.CompileTime,
            execution.ExecutionTime,
            compilation.Diagnostics,
            compilation.ArtifactId,
            assemblyBytes = compilation.AssemblyBytes!.Length,
            execution.LightPT
        };
    }

    private static object CheckForApi(RuntimeRequest request)
    {
        var compilation = Compile(request.Code ?? string.Empty, null);
        if (!compilation.Success)
            return new
            {
                success = false,
                passed = 0,
                failed = request.Tests?.Count ?? 0,
                tests = Array.Empty<object>(),
                compilation.CompileTime,
                compilation.Diagnostics
            };

        var comparison = request.Comparison ?? new ComparisonOptions();
        var testResults = new List<object>();
        var passed = 0;
        foreach (var test in request.Tests ?? new List<TestCase>())
        {
            var execution = Execute(compilation, test.Input ?? string.Empty);
            var expected = test.Expected ?? string.Empty;
            var testPassed = execution.ExitCode == 0
                && string.Equals(Normalize(execution.Stdout, comparison), Normalize(expected, comparison), StringComparison.Ordinal);
            if (testPassed)
                passed++;
            testResults.Add(new
            {
                input = test.Input ?? string.Empty,
                expected,
                actual = execution.Stdout,
                execution.Stderr,
                execution.ExitCode,
                passed = testPassed
            });
        }

        return new
        {
            success = true,
            passed,
            failed = testResults.Count - passed,
            tests = testResults,
            compilation.CompileTime,
            compilation.Diagnostics
        };
    }

    private static CompiledProgram Compile(string code, LightPTConfiguration? lightPT)
    {
        if (lightPT is not null && string.IsNullOrWhiteSpace(lightPT.Tasks))
            throw new ArgumentException("lightPT.tasks must contain the hidden Tasks.pas source.");

        var id = Interlocked.Increment(ref nextProgramId);
        var compilationDirectory = Path.Combine(WorkDirectory, $"program_{id:D6}");
        Directory.CreateDirectory(compilationDirectory);
        var sourcePath = Path.Combine(compilationDirectory, $"program_{id:D6}.pas");
        string? outputPath = null;
        try
        {
            File.WriteAllText(sourcePath, code);
            if (lightPT is not null)
            {
                // This mirrors desktop PascalABC.NET: the syntax converter sees
                // lightpt.dat and injects `uses LightPT, Tasks` into the program.
                // The student's source stays untouched and never names either unit.
                File.WriteAllText(Path.Combine(compilationDirectory, "Tasks.pas"), lightPT.Tasks!);
                File.WriteAllText(Path.Combine(compilationDirectory, "lightpt.dat"), "PascalABC.Web");
            }

            var compiler = new Compiler();
            var options = new CompilerOptions(sourcePath, CompilerOptions.OutputType.ConsoleApplicaton)
            {
                Debug = false,
                Rebuild = false,
                SavePCU = false,
                SaveDocumentation = false,
                OutputDirectory = WorkDirectory,
                SystemDirectory = Root,
                SearchDirectories = new List<string>(),
                StandardDirectories = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                {
                    ["%PABCSYSTEM%"] = Root
                }
            };

            var timer = Stopwatch.StartNew();
            outputPath = compiler.Compile(options);
            timer.Stop();
            var diagnostics = compiler.ErrorsList.Select(error => ToDiagnostic(error))
                .Concat(compiler.Warnings.Select(error => ToDiagnostic(error, "warning")))
                .ToArray();
            var bytes = outputPath is not null && compiler.ErrorsList.Count == 0
                ? File.ReadAllBytes(outputPath)
                : null;

            return new CompiledProgram(
                $"pabc-{id:D6}",
                bytes,
                timer.Elapsed.TotalMilliseconds,
                diagnostics,
                lightPT is not null,
                string.IsNullOrWhiteSpace(lightPT?.TaskName) ? $"program_{id:D6}" : lightPT.TaskName!);
        }
        finally
        {
            if (outputPath is not null)
            {
                TryDelete(outputPath);
                TryDelete(Path.ChangeExtension(outputPath, ".pdb"));
                TryDelete(Path.ChangeExtension(outputPath, ".runtimeconfig.json"));
            }
            // Hidden Tasks.pas must never remain readable by a later program,
            // including when compilation throws before diagnostics are returned.
            TryDeleteDirectory(compilationDirectory);
        }
    }

    private static void TryDelete(string path)
    {
        try
        {
            if (File.Exists(path))
                File.Delete(path);
        }
        catch
        {
            // The in-memory browser filesystem is disposed with the worker;
            // cleanup must never hide a compiler result.
        }
    }

    private static void TryDeleteDirectory(string path)
    {
        try
        {
            if (Directory.Exists(path))
                Directory.Delete(path, true);
        }
        catch
        {
            // The browser VFS is ephemeral; failed cleanup must not hide a result.
        }
    }

    private static ExecutionResult Execute(CompiledProgram compilation, string stdin)
    {
        using var input = new StringReader(stdin);
        using var output = new StringWriter();
        using var error = new StringWriter();
        var exitCode = 0;
        var timer = Stopwatch.StartNew();
        try
        {
            BrowserGraphicsBridge.BeginExecution();
            AppDomain.CurrentDomain.SetData(StdinKey, input);
            AppDomain.CurrentDomain.SetData(StdoutKey, output);
            AppDomain.CurrentDomain.SetData(LightPTTaskNameKey, compilation.LightPTEnabled ? compilation.TaskName : null);
            AppDomain.CurrentDomain.SetData(LightPTResultKey, null);
            var assembly = Assembly.Load(compilation.AssemblyBytes!);
            var entryPoint = assembly.EntryPoint
                ?? throw new InvalidOperationException("Generated assembly has no entry point.");
            if (entryPoint.GetParameters().Length == 0 && entryPoint.ReturnType == typeof(void))
                entryPoint.CreateDelegate<Action>()();
            else
                entryPoint.Invoke(null, new object?[] { Array.Empty<string>() });
        }
        catch (TargetInvocationException exception)
        {
            exitCode = 1;
            error.Write(exception.InnerException ?? exception);
        }
        catch (Exception exception)
        {
            exitCode = 1;
            error.Write(exception);
        }
        finally
        {
            timer.Stop();
            AppDomain.CurrentDomain.SetData(StdinKey, null);
            AppDomain.CurrentDomain.SetData(StdoutKey, null);
        }

        var lightPTStatus = AppDomain.CurrentDomain.GetData(LightPTResultKey) as string;
        var lightPT = compilation.LightPTEnabled
            ? new LightPTExecutionResult(
                lightPTStatus is not null && !string.Equals(lightPTStatus, "NotUnderControl", StringComparison.Ordinal),
                compilation.TaskName,
                lightPTStatus ?? "NotUnderControl",
                string.Equals(lightPTStatus, "Solved", StringComparison.Ordinal))
            : null;
        AppDomain.CurrentDomain.SetData(LightPTTaskNameKey, null);
        AppDomain.CurrentDomain.SetData(LightPTResultKey, null);

        return new ExecutionResult(
            output.ToString(),
            error.ToString(),
            exitCode,
            timer.Elapsed.TotalMilliseconds,
            lightPT);
    }

    private static object CompilationResponse(CompiledProgram compilation) => new
    {
        success = compilation.Success,
        stdout = string.Empty,
        stderr = string.Empty,
        exitCode = compilation.Success ? 0 : 1,
        compilation.CompileTime,
        executionTime = 0d,
        compilation.Diagnostics,
        artifactId = compilation.Success ? compilation.ArtifactId : null,
        assemblyBytes = compilation.AssemblyBytes?.Length ?? 0
    };

    private static Diagnostic ToDiagnostic(Error error, string severity = "error")
    {
        var location = (error as LocatedError)?.SourceLocation;
        return new Diagnostic(
            location?.BeginPosition.Line ?? 0,
            location?.BeginPosition.Column ?? 0,
            severity,
            error.GetType().Name,
            error.Message);
    }

    private static string Normalize(string value, ComparisonOptions options)
    {
        if (options.NormalizeNewlines)
            value = value.Replace("\r\n", "\n").Replace('\r', '\n');
        if (options.TrimTrailingWhitespace)
            value = string.Join("\n", value.Split('\n').Select(line => line.TrimEnd()));
        if (options.IgnoreTrailingNewline)
            value = value.TrimEnd('\n');
        return value;
    }

    private sealed record CompiledProgram(
        string ArtifactId,
        byte[]? AssemblyBytes,
        double CompileTime,
        Diagnostic[] Diagnostics,
        bool LightPTEnabled,
        string TaskName)
    {
        public bool Success => AssemblyBytes is not null && Diagnostics.All(item => item.Severity != "error");
    }

    private sealed record ExecutionResult(
        string Stdout,
        string Stderr,
        int ExitCode,
        double ExecutionTime,
        LightPTExecutionResult? LightPT);
    private sealed record LightPTExecutionResult(bool Checked, string TaskName, string Status, bool Passed);
    private sealed record Diagnostic(int Line, int Column, string Severity, string Code, string Message);

    private sealed class RuntimeRequest
    {
        public string? Operation { get; set; }
        public string? BaseUrl { get; set; }
        public string? Code { get; set; }
        public string? Stdin { get; set; }
        public string? ArtifactId { get; set; }
        public LightPTConfiguration? LightPT { get; set; }
        public List<TestCase>? Tests { get; set; }
        public ComparisonOptions? Comparison { get; set; }
    }

    private sealed class LightPTConfiguration
    {
        public string? Tasks { get; set; }
        public string? TaskName { get; set; }
    }

    private sealed class TestCase
    {
        public string? Input { get; set; }
        public string? Expected { get; set; }
    }

    private sealed class ComparisonOptions
    {
        public bool TrimTrailingWhitespace { get; set; } = true;
        public bool NormalizeNewlines { get; set; } = true;
        public bool IgnoreTrailingNewline { get; set; }
    }
}
