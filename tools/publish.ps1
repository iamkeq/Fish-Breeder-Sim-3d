# Builds the 3D game for the web and Windows and uploads both to itch.io
# (figtreegames/fish-breeding-store-sim-3d, channels "html5" and "windows").
#   .\tools\publish.ps1            # version from project.godot
#   .\tools\publish.ps1 0.4.5
# Needs: Godot 4.7.2 (path below) with web and Windows export templates, the Synty
# packs in assets/ (see README), and butler logged in (butler.exe login, once).
# Stops if any unit test fails. Refreshes the list of Synty files left out of the
# builds first (tools/export_filter.gd), so new models are never missing.
param([string]$Version = "")

$ErrorActionPreference = "Stop"
$godot = "G:\2026 Downloads\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
$butler = Join-Path $env:LOCALAPPDATA "butler\butler.exe"
$project = Split-Path $PSScriptRoot -Parent
$page = "figtreegames/fish-breeding-store-sim-3d"

Push-Location $project
try {
	if ($Version -eq "") {
		$Version = (Select-String -Path project.godot -Pattern 'config/version="([^"]+)"').Matches[0].Groups[1].Value
	}
	& $godot --headless --path . -s res://tests/run_tests.gd
	if ($LASTEXITCODE -ne 0) { throw "Unit tests failed; not publishing." }

	& $godot --headless --path . res://tools/export_filter.tscn
	if ($LASTEXITCODE -ne 0) { throw "Export filter failed." }

	foreach ($build in @(
		@{ Preset = "Web"; Dir = "build/web"; File = "index.html"; Channel = "html5" },
		@{ Preset = "Windows Desktop"; Dir = "build/windows"; File = "FishBreeder.exe"; Channel = "windows" }
	)) {
		if (Test-Path $build.Dir) { Remove-Item -Recurse -Force $build.Dir }
		New-Item -ItemType Directory -Force $build.Dir | Out-Null
		& $godot --headless --path . --export-release $build.Preset "$($build.Dir)/$($build.File)"
		if ($LASTEXITCODE -ne 0) { throw "$($build.Preset) export failed." }
		& $butler push $build.Dir "${page}:$($build.Channel)" --userversion $Version
		if ($LASTEXITCODE -ne 0) { throw "butler push ($($build.Channel)) failed." }
	}
	& $butler status $page
}
finally {
	Pop-Location
}
