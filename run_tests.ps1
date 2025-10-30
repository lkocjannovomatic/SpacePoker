# run_tests.ps1 - Run gdUnit4 tests for SpacePoker
# Usage: .\run_tests.ps1 [test_file_path]
# Example: .\run_tests.ps1 tests/unit/test_poker_engine.gd

param(
    [string]$TestFile = ""
)

$GodotPath = "D:\10xDevs\Godot_v4.5.1-stable_win64_console.exe"

if (-not (Test-Path $GodotPath)) {
    Write-Host "Error: Godot executable not found at $GodotPath" -ForegroundColor Red
    exit 1
}

Write-Host "Running tests with Godot 4.5.1..." -ForegroundColor Cyan

if ($TestFile) {
    # Run specific test file
    Write-Host "Testing: $TestFile" -ForegroundColor Yellow
    & $GodotPath --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd --add $TestFile --ignoreHeadlessMode
} else {
    # Run all tests
    Write-Host "Running all tests..." -ForegroundColor Yellow
    & $GodotPath --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd --add tests/unit/ --add tests/integration/ --ignoreHeadlessMode
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nAll tests passed! ✓" -ForegroundColor Green
} else {
    Write-Host "`nTests failed! ✗" -ForegroundColor Red
    exit $LASTEXITCODE
}
