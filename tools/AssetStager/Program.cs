using System.Text.Json;
using PascalABCCompiler.NetHelper;

if (args.Length != 2)
{
    Console.Error.WriteLine("Usage: AssetStager <pascalabc-bin> <destination>");
    return 2;
}

var pascalBin = Path.GetFullPath(args[0]);
var destination = Path.GetFullPath(args[1]);
var runtimeDestination = Path.Combine(destination, "runtime");
var libraryDestination = Path.Combine(destination, "Lib");
Directory.CreateDirectory(runtimeDestination);
Directory.CreateDirectory(libraryDestination);

var assets = new List<string>();
var runtimeAssets = NetCoreSystemReferences.AssemblyPaths
    .Concat(new[]
    {
        Path.Combine(NetCoreSystemReferences.RuntimeDirectory, "mscorlib.dll"),
        Path.Combine(NetCoreSystemReferences.RuntimeDirectory, "System.dll"),
        Path.Combine(NetCoreSystemReferences.RuntimeDirectory, "System.Core.dll"),
        Path.Combine(NetCoreSystemReferences.RuntimeDirectory, "netstandard.dll"),
        Path.Combine(pascalBin, "Lib", "PascalABC.Web.Graphics.dll")
    })
    .Distinct(StringComparer.OrdinalIgnoreCase);

foreach (var assemblyPath in runtimeAssets)
{
    if (!File.Exists(assemblyPath))
        throw new FileNotFoundException($".NET runtime asset is missing: {assemblyPath}");

    var destinationPath = Path.Combine(runtimeDestination, Path.GetFileName(assemblyPath));
    File.Copy(assemblyPath, destinationPath, true);
    assets.Add(Path.GetRelativePath(destination, destinationPath).Replace('\\', '/'));
}

foreach (var fileName in new[]
         {
             "PABCSystem.pcu",
             "PABCExtensions.pcu",
             "PABCSystem.pas",
             "PABCExtensions.pas",
             "GraphWPF.pcu",
             "GraphWPF.pas",
             "Graph3D.pcu",
             "Graph3D.pas"
         })
{
    var sourcePath = Path.Combine(pascalBin, "Lib", fileName);
    if ((fileName.Equals("PABCSystem.pas", StringComparison.OrdinalIgnoreCase)
         || fileName.Equals("PABCExtensions.pas", StringComparison.OrdinalIgnoreCase)))
    {
        var repositorySourcePath = Path.Combine(
            Directory.GetParent(pascalBin)?.FullName ?? pascalBin,
            "bin", "Lib", fileName);
        if (File.Exists(repositorySourcePath))
            sourcePath = repositorySourcePath;
    }
    if (!File.Exists(sourcePath))
        throw new FileNotFoundException($"PascalABC.NET standard library asset is missing: {sourcePath}");

    var destinationPath = Path.Combine(libraryDestination, fileName);
    File.Copy(sourcePath, destinationPath, true);
    assets.Add(Path.GetRelativePath(destination, destinationPath).Replace('\\', '/'));
}

assets.Sort(StringComparer.Ordinal);
File.WriteAllText(
    Path.Combine(destination, "manifest.json"),
    JsonSerializer.Serialize(assets, new JsonSerializerOptions { WriteIndented = true }));

Console.WriteLine($"Staged {assets.Count} files ({assets.Sum(asset => new FileInfo(Path.Combine(destination, asset)).Length)} bytes).");
return 0;
