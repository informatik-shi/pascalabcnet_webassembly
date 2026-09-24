#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
upstream_root="$repo_root/upstream/pascalabcnet"
browser_patch="$repo_root/patches/pascalabcnet-browser.patch"
configuration="${CONFIGURATION:-Release}"
if [[ -x "$repo_root/.dotnet/dotnet" ]]; then
  dotnet_cmd="${DOTNET_CMD:-$repo_root/.dotnet/dotnet}"
  export DOTNET_ROOT="${DOTNET_ROOT:-$repo_root/.dotnet}"
else
  dotnet_cmd="${DOTNET_CMD:-dotnet}"
fi
export DOTNET_CLI_HOME="${DOTNET_CLI_HOME:-$repo_root/.dotnet-home}"
export NUGET_PACKAGES="${NUGET_PACKAGES:-$repo_root/.nuget/packages}"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
mkdir -p "$DOTNET_CLI_HOME" "$NUGET_PACKAGES"

reset_generated_directory() {
  local requested="$1"
  local target
  mkdir -p -- "$(dirname "$requested")"
  target="$(cd "$(dirname "$requested")" && pwd -P)/$(basename "$requested")"
  case "$target" in
    "$repo_root"/*) ;;
    *) echo "Refusing to reset a directory outside the repository: $target" >&2; exit 1 ;;
  esac
  rm -rf -- "$target"
  mkdir -p -- "$target"
}

if [[ ! -f "$upstream_root/Compiler/Compiler.csproj" ]]; then
  git -C "$repo_root" submodule update --init --recursive
fi
if git -C "$upstream_root" apply --ignore-space-change --check "$browser_patch" 2>/dev/null; then
  git -C "$upstream_root" apply --ignore-space-change "$browser_patch"
elif ! git -C "$upstream_root" apply --ignore-space-change --check --reverse "$browser_patch" 2>/dev/null; then
  echo "The PascalABC.NET browser patch cannot be applied cleanly." >&2
  exit 1
fi

"$dotnet_cmd" build "$upstream_root/pabcnetc.sln" -c "$configuration" -p:TargetFramework=net10.0 -m:1
cp "$upstream_root/bin/Lib/PABCSystem.pas" "$upstream_root/bin-net10/Lib/PABCSystem.pas"
cp "$upstream_root/bin/Lib/PABCExtensions.pas" "$upstream_root/bin-net10/Lib/PABCExtensions.pas"

bootstrap_dir="$repo_root/artifacts/bootstrap"
reset_generated_directory "$bootstrap_dir"
cp "$repo_root/tests/programs/01_hello.pas" "$bootstrap_dir/bootstrap.pas"
"$dotnet_cmd" "$upstream_root/bin-net10/pabcnetc.dll" "$bootstrap_dir/bootstrap.pas" /rebuild /noconsole

"$dotnet_cmd" build "$repo_root/src/PascalABC.Web.Graphics/PascalABC.Web.Graphics.csproj" -c "$configuration"
cp "$repo_root/browser-units/GraphWPF.pas" "$upstream_root/bin-net10/Lib/GraphWPF.pas"
cp "$repo_root/src/PascalABC.Web.Graphics/bin/$configuration/net10.0/PascalABC.Web.Graphics.dll" "$upstream_root/bin-net10/Lib/PascalABC.Web.Graphics.dll"
graphics_bootstrap_dir="$repo_root/artifacts/graphics"
reset_generated_directory "$graphics_bootstrap_dir"
cp "$repo_root/tests/graphics/graphwpf-basic.pas" "$graphics_bootstrap_dir/graphwpf-basic.pas"
"$dotnet_cmd" "$upstream_root/bin-net10/pabcnetc.dll" "$graphics_bootstrap_dir/graphwpf-basic.pas" /rebuild /noconsole
test -f "$upstream_root/bin-net10/Lib/GraphWPF.pcu"

cp "$repo_root/browser-units/PlotWPF.pas" "$upstream_root/bin-net10/Lib/PlotWPF.pas"
plot_bootstrap_dir="$repo_root/artifacts/plotwpf"
reset_generated_directory "$plot_bootstrap_dir"
cp "$repo_root/tests/graphics/plotwpf-basic.pas" "$plot_bootstrap_dir/plotwpf-basic.pas"
"$dotnet_cmd" "$upstream_root/bin-net10/pabcnetc.dll" "$plot_bootstrap_dir/plotwpf-basic.pas" /rebuild /noconsole
test -f "$upstream_root/bin-net10/Lib/PlotWPF.pcu"

cp "$repo_root/browser-units/Graph3D.pas" "$upstream_root/bin-net10/Lib/Graph3D.pas"
graphics3d_bootstrap_dir="$repo_root/artifacts/graphics3d"
reset_generated_directory "$graphics3d_bootstrap_dir"
cp "$repo_root/tests/graphics/graph3d-basic.pas" "$graphics3d_bootstrap_dir/graph3d-basic.pas"
"$dotnet_cmd" "$upstream_root/bin-net10/pabcnetc.dll" "$graphics3d_bootstrap_dir/graph3d-basic.pas" /rebuild /noconsole
test -f "$upstream_root/bin-net10/Lib/Graph3D.pcu"

cp "$repo_root/browser-units/LightPT.pas" "$upstream_root/bin-net10/Lib/LightPT.pas"
lightpt_bootstrap_dir="$repo_root/artifacts/lightpt"
reset_generated_directory "$lightpt_bootstrap_dir"
cp "$repo_root/tests/lightpt/Program.pas" "$lightpt_bootstrap_dir/Program.pas"
cp "$repo_root/tests/lightpt/Tasks.pas" "$lightpt_bootstrap_dir/Tasks.pas"
printf '%s\n' 'PascalABC.Web' > "$lightpt_bootstrap_dir/lightpt.dat"
"$dotnet_cmd" "$upstream_root/bin-net10/pabcnetc.dll" "$lightpt_bootstrap_dir/Program.pas" /rebuild /noconsole
test -f "$upstream_root/bin-net10/Lib/LightPT.pcu"

asset_dir="$repo_root/src/PascalABC.Web.Runtime/wwwroot/pabc-assets"
reset_generated_directory "$asset_dir"
"$dotnet_cmd" run --project "$repo_root/tools/AssetStager/AssetStager.csproj" -c "$configuration" -- "$upstream_root/bin-net10" "$asset_dir"
"$dotnet_cmd" publish "$repo_root/src/PascalABC.Web.Runtime/PascalABC.Web.Runtime.csproj" -c "$configuration"

publish_dir="$repo_root/src/PascalABC.Web.Runtime/bin/$configuration/net10.0/publish/wwwroot"
dist_dir="$repo_root/dist"
reset_generated_directory "$dist_dir"
cp -R "$publish_dir/." "$dist_dir/"
find "$dist_dir" -type f -name '*.gz' -delete
cp "$repo_root/js/pascalabc-web.js" "$repo_root/js/pascalabc-worker.js" "$repo_root/js/pascalabc-graphics.js" "$repo_root/js/pascalabc-web.d.ts" "$dist_dir/"
mkdir -p "$dist_dir/licenses"
cp "$upstream_root/doc/License_en.txt" "$dist_dir/licenses/PascalABC.NET-LICENSE.txt"

find "$dist_dir" -maxdepth 2 -type f \( -name 'pascalabc-*.js' -o -name 'dotnet.native*.wasm' \) -print | while IFS= read -r file; do
  bytes="$(wc -c < "$file" | tr -d ' ')"
  printf '%s %s bytes\n' "${file#"$dist_dir/"}" "$bytes"
done
echo "Build complete: $dist_dir"
