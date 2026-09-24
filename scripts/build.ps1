[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',
    [switch]$SkipUpstreamBuild
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$upstreamRoot = Join-Path $repositoryRoot 'upstream\pascalabcnet'
$browserPatch = Join-Path $repositoryRoot 'patches\pascalabcnet-browser.patch'
$runtimeProject = Join-Path $repositoryRoot 'src\PascalABC.Web.Runtime\PascalABC.Web.Runtime.csproj'
$graphicsProject = Join-Path $repositoryRoot 'src\PascalABC.Web.Graphics\PascalABC.Web.Graphics.csproj'
$graphicsUnit = Join-Path $repositoryRoot 'browser-units\GraphWPF.pas'
$graphicsTest = Join-Path $repositoryRoot 'tests\graphics\graphwpf-basic.pas'
$plotUnit = Join-Path $repositoryRoot 'browser-units\PlotWPF.pas'
$plotTest = Join-Path $repositoryRoot 'tests\graphics\plotwpf-basic.pas'
$graphics3DUnit = Join-Path $repositoryRoot 'browser-units\Graph3D.pas'
$graphics3DTest = Join-Path $repositoryRoot 'tests\graphics\graph3d-basic.pas'
$lightPTUnit = Join-Path $repositoryRoot 'browser-units\LightPT.pas'
$lightPTTestDirectory = Join-Path $repositoryRoot 'tests\lightpt'
$assetDestination = Join-Path $repositoryRoot 'src\PascalABC.Web.Runtime\wwwroot\pabc-assets'
$publishDirectory = Join-Path $repositoryRoot "src\PascalABC.Web.Runtime\bin\$Configuration\net10.0\publish\wwwroot"
$distributionDirectory = Join-Path $repositoryRoot 'dist'
$localDotnet = Join-Path $repositoryRoot '.dotnet\dotnet.exe'
$dotnet = if (Test-Path -LiteralPath $localDotnet) { $localDotnet } else { (Get-Command dotnet -ErrorAction Stop).Source }
$env:DOTNET_CLI_HOME = Join-Path $repositoryRoot '.dotnet-home'
$env:NUGET_PACKAGES = Join-Path $repositoryRoot '.nuget\packages'
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'
if (Test-Path -LiteralPath $localDotnet) {
    $env:DOTNET_ROOT = Join-Path $repositoryRoot '.dotnet'
}
New-Item -ItemType Directory -Path $env:DOTNET_CLI_HOME -Force | Out-Null
New-Item -ItemType Directory -Path $env:NUGET_PACKAGES -Force | Out-Null

function Assert-LastExitCode([string]$Description) {
    if ($LASTEXITCODE -ne 0) {
        throw "$Description failed with exit code $LASTEXITCODE."
    }
}

function Reset-GeneratedDirectory([string]$Path) {
    $fullPath = [IO.Path]::GetFullPath($Path)
    if (-not $fullPath.StartsWith($repositoryRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to reset a directory outside the repository: $fullPath"
    }
    if (Test-Path -LiteralPath $fullPath) {
        Remove-Item -LiteralPath $fullPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $fullPath | Out-Null
}

Push-Location $repositoryRoot
try {
    if (-not (Test-Path -LiteralPath (Join-Path $upstreamRoot 'Compiler\Compiler.csproj'))) {
        git submodule update --init --recursive
        Assert-LastExitCode 'git submodule update'
    }

    $savedErrorPreference = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    git -C $upstreamRoot apply --ignore-space-change --check $browserPatch 2>$null
    $patchCanApply = $LASTEXITCODE -eq 0
    $ErrorActionPreference = $savedErrorPreference
    if ($patchCanApply) {
        git -C $upstreamRoot apply --ignore-space-change $browserPatch
        Assert-LastExitCode 'PascalABC.NET browser patch'
    }
    else {
        $ErrorActionPreference = 'SilentlyContinue'
        git -C $upstreamRoot apply --ignore-space-change --check --reverse $browserPatch 2>$null
        $reversePatchIsValid = $LASTEXITCODE -eq 0
        $ErrorActionPreference = $savedErrorPreference
        if (-not $reversePatchIsValid) {
            throw 'PascalABC.NET browser patch is neither cleanly applicable nor already applied.'
        }
        Assert-LastExitCode 'PascalABC.NET browser patch validation'
        Write-Host 'PascalABC.NET browser patch is already applied.'
    }

    if (-not $SkipUpstreamBuild) {
        & $dotnet build (Join-Path $upstreamRoot 'pabcnetc.sln') -c $Configuration -p:TargetFramework=net10.0 -m:1
        Assert-LastExitCode 'PascalABC.NET .NET 10 build'
    }

    $pascalBin = Join-Path $upstreamRoot 'bin-net10'
    $pascalLib = Join-Path $pascalBin 'Lib'
    Copy-Item -LiteralPath (Join-Path $upstreamRoot 'bin\Lib\PABCSystem.pas') -Destination $pascalLib -Force
    Copy-Item -LiteralPath (Join-Path $upstreamRoot 'bin\Lib\PABCExtensions.pas') -Destination $pascalLib -Force

    $bootstrapDirectory = Join-Path $repositoryRoot 'artifacts\bootstrap'
    Reset-GeneratedDirectory $bootstrapDirectory
    $bootstrapSource = Join-Path $bootstrapDirectory 'bootstrap.pas'
    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'tests\programs\01_hello.pas') -Destination $bootstrapSource
    & $dotnet (Join-Path $pascalBin 'pabcnetc.dll') $bootstrapSource /rebuild /noconsole
    Assert-LastExitCode 'PascalABC.NET standard library rebuild'

    & $dotnet build $graphicsProject -c $Configuration
    Assert-LastExitCode 'browser graphics bridge build'
    Copy-Item -LiteralPath $graphicsUnit -Destination (Join-Path $pascalLib 'GraphWPF.pas') -Force
    Copy-Item -LiteralPath (Join-Path $repositoryRoot "src\PascalABC.Web.Graphics\bin\$Configuration\net10.0\PascalABC.Web.Graphics.dll") -Destination $pascalLib -Force
    $graphicsBootstrapDirectory = Join-Path $repositoryRoot 'artifacts\graphics'
    Reset-GeneratedDirectory $graphicsBootstrapDirectory
    $graphicsBootstrapSource = Join-Path $graphicsBootstrapDirectory 'graphwpf-basic.pas'
    Copy-Item -LiteralPath $graphicsTest -Destination $graphicsBootstrapSource
    & $dotnet (Join-Path $pascalBin 'pabcnetc.dll') $graphicsBootstrapSource /rebuild /noconsole
    Assert-LastExitCode 'GraphWPF browser unit rebuild'
    if (-not (Test-Path -LiteralPath (Join-Path $pascalLib 'GraphWPF.pcu'))) {
        throw 'GraphWPF browser unit did not produce GraphWPF.pcu.'
    }
    Copy-Item -LiteralPath $plotUnit -Destination (Join-Path $pascalLib 'PlotWPF.pas') -Force
    $plotBootstrapDirectory = Join-Path $repositoryRoot 'artifacts\plotwpf'
    Reset-GeneratedDirectory $plotBootstrapDirectory
    $plotBootstrapSource = Join-Path $plotBootstrapDirectory 'plotwpf-basic.pas'
    Copy-Item -LiteralPath $plotTest -Destination $plotBootstrapSource
    & $dotnet (Join-Path $pascalBin 'pabcnetc.dll') $plotBootstrapSource /rebuild /noconsole
    Assert-LastExitCode 'PlotWPF browser unit rebuild'
    if (-not (Test-Path -LiteralPath (Join-Path $pascalLib 'PlotWPF.pcu'))) {
        throw 'PlotWPF browser unit did not produce PlotWPF.pcu.'
    }
    Copy-Item -LiteralPath $graphics3DUnit -Destination (Join-Path $pascalLib 'Graph3D.pas') -Force
    $graphics3DBootstrapDirectory = Join-Path $repositoryRoot 'artifacts\graphics3d'
    Reset-GeneratedDirectory $graphics3DBootstrapDirectory
    $graphics3DBootstrapSource = Join-Path $graphics3DBootstrapDirectory 'graph3d-basic.pas'
    Copy-Item -LiteralPath $graphics3DTest -Destination $graphics3DBootstrapSource
    & $dotnet (Join-Path $pascalBin 'pabcnetc.dll') $graphics3DBootstrapSource /rebuild /noconsole
    Assert-LastExitCode 'Graph3D browser unit rebuild'
    if (-not (Test-Path -LiteralPath (Join-Path $pascalLib 'Graph3D.pcu'))) {
        throw 'Graph3D browser unit did not produce Graph3D.pcu.'
    }
    Copy-Item -LiteralPath $lightPTUnit -Destination (Join-Path $pascalLib 'LightPT.pas') -Force
    $lightPTBootstrapDirectory = Join-Path $repositoryRoot 'artifacts\lightpt'
    Reset-GeneratedDirectory $lightPTBootstrapDirectory
    $lightPTBootstrapSource = Join-Path $lightPTBootstrapDirectory 'Program.pas'
    Copy-Item -LiteralPath (Join-Path $lightPTTestDirectory 'Program.pas') -Destination $lightPTBootstrapSource
    Copy-Item -LiteralPath (Join-Path $lightPTTestDirectory 'Tasks.pas') -Destination (Join-Path $lightPTBootstrapDirectory 'Tasks.pas')
    Set-Content -LiteralPath (Join-Path $lightPTBootstrapDirectory 'lightpt.dat') -Value 'PascalABC.Web' -Encoding utf8
    & $dotnet (Join-Path $pascalBin 'pabcnetc.dll') $lightPTBootstrapSource /rebuild /noconsole
    Assert-LastExitCode 'LightPT browser unit rebuild'
    if (-not (Test-Path -LiteralPath (Join-Path $pascalLib 'LightPT.pcu'))) {
        throw 'LightPT browser unit did not produce LightPT.pcu.'
    }

    Reset-GeneratedDirectory $assetDestination
    & $dotnet run --project (Join-Path $repositoryRoot 'tools\AssetStager\AssetStager.csproj') -c $Configuration -- $pascalBin $assetDestination
    Assert-LastExitCode 'browser asset staging'

    & $dotnet publish $runtimeProject -c $Configuration
    Assert-LastExitCode 'WebAssembly publish'

    Reset-GeneratedDirectory $distributionDirectory
    Copy-Item -Path (Join-Path $publishDirectory '*') -Destination $distributionDirectory -Recurse -Force
    # Keep raw fallback plus Brotli. Shipping an additional gzip copy makes the
    # npm tarball much larger without helping current Chrome/Edge deployments.
    Get-ChildItem -LiteralPath $distributionDirectory -Filter '*.gz' -File -Recurse | Remove-Item -Force
    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'js\pascalabc-web.js') -Destination $distributionDirectory
    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'js\pascalabc-worker.js') -Destination $distributionDirectory
    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'js\pascalabc-graphics.js') -Destination $distributionDirectory
    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'js\pascalabc-web.d.ts') -Destination $distributionDirectory
    $licenseDirectory = Join-Path $distributionDirectory 'licenses'
    New-Item -ItemType Directory -Path $licenseDirectory | Out-Null
    Copy-Item -LiteralPath (Join-Path $upstreamRoot 'doc\License_en.txt') -Destination (Join-Path $licenseDirectory 'PascalABC.NET-LICENSE.txt')

    $sizeTargets = @(
        (Join-Path $distributionDirectory 'pascalabc-web.js'),
        (Join-Path $distributionDirectory 'pascalabc-worker.js'),
        (Join-Path $distributionDirectory 'pascalabc-graphics.js')
    ) + (Get-ChildItem -LiteralPath (Join-Path $distributionDirectory '_framework') -Filter 'dotnet.native*.wasm' | Select-Object -ExpandProperty FullName)
    $sizeTargets | ForEach-Object {
        $file = Get-Item -LiteralPath $_
        '{0,-42} {1,12:N0} bytes' -f $file.FullName.Substring($distributionDirectory.Length + 1), $file.Length
    }
    $assetBytes = (Get-ChildItem -LiteralPath (Join-Path $distributionDirectory 'pabc-assets') -File -Recurse | Measure-Object Length -Sum).Sum
    'pabc-assets (raw + Brotli)                {0,12:N0} bytes' -f $assetBytes
    Write-Host "Build complete: $distributionDirectory"
}
finally {
    Pop-Location
}
