# build_nomad46_win_mex.ps1
# One-click builder for NOMAD 4.6.0 MATLAB MEX (nomadOpt.mexw64) on Windows.
# This is the Windows counterpart to build_nomad46_linux_mex.sh.
#
# Usage (from PowerShell, in repo root):
#   powershell -ExecutionPolicy Bypass -File .\build_nomad46_win_mex.ps1
#   # or with custom repo root:
#   .\build_nomad46_win_mex.ps1 -RepoRoot "C:\path\to\tot"
#
# What it does (same as the manual build that produced the current v4.6/win64/nomadOpt.mexw64):
#   1. Locates MATLAB (via $env:MATLAB_ROOT or `where matlab`) and Visual Studio 2022 (via vswhere or default path)
#   2. Ensures cmake is available (via winget or temp download)
#   3. Downloads NOMAD 4.6.0 source to temp (if not already cached)
#   4. Configures: cmake -DTEST_OPENMP=OFF -DBUILD_INTERFACE_MATLAB=ON -DMatlab_ROOT_DIR=... -S . -B build/release -A x64
#   5. Builds: cmake --build build/release --config Release
#   6. Copies nomadOpt.mexw64 + DLLs to helper_methods\math\nomad\v4.6\win64
#   7. Verifies via `nomad.exe -v` and a minimal MATLAB smoke test
#
# Requirements:
#   - MATLAB R2020a+ with MEX support (Microsoft Visual C++ 2022, 17.x)
#   - Visual Studio 2022 Community/Professional/Enterprise with "Desktop development with C++"
#   - cmake >= 3.15 (auto-installed via winget if missing)
#   - Internet access
#
# The resulting layout matches the Linux install:
#   helper_methods\math\nomad\v4.6\win64\nomadOpt.mexw64  (MEX, ~74k)
#   helper_methods\math\nomad\v4.6\win64\nomadAlgos.dll etc.
#   helper_methods\math\nomad\v4.6\win64\nomad.exe         (standalone)
#
# If you only need the standalone binaries, they are already in
# helper_methods\math\nomad\v4.6\win64\ from the binary release.
# This script is only needed to (re)build the MATLAB MEX.
#
# Exit codes: 0 on success.

param(
    [string]$RepoRoot = $null,
    [string]$MatlabRoot = $null,
    [switch]$NoSmokeTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- Resolve repo root ---
if (-not $RepoRoot) {
    $RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if (-not (Test-Path (Join-Path $RepoRoot "helper_methods"))) {
    Write-Error "Repo root not found at $RepoRoot (missing helper_methods). Pass -RepoRoot explicitly."
    exit 1
}
Write-Host "=== NOMAD 4.6.0 Windows MEX Builder ===" -ForegroundColor Cyan
Write-Host "Repo root: $RepoRoot"

# --- Locate MATLAB ---
if (-not $MatlabRoot) { $MatlabRoot = $env:MATLAB_ROOT }
if (-not $MatlabRoot) {
    $matlabCmd = Get-Command matlab -ErrorAction SilentlyContinue
    if ($matlabCmd) {
        # Try to get matlabroot via batch
        try {
            $out = & "$($matlabCmd.Source)" -batch "disp(matlabroot); exit" 2>&1 | Out-String
            $MatlabRoot = ($out -split "`r?`n" | Where-Object { $_ -match "MATLAB" } | Select-Object -Last 1).Trim()
            if (-not $MatlabRoot -or -not (Test-Path $MatlabRoot)) {
                $MatlabRoot = Split-Path -Parent (Split-Path -Parent $matlabCmd.Source)
            }
        } catch {
            $MatlabRoot = Split-Path -Parent (Split-Path -Parent $matlabCmd.Source)
        }
    }
}
if (-not $MatlabRoot -or -not (Test-Path $MatlabRoot)) {
    # Try common locations
    foreach ($cand in @("C:\Program Files\MATLAB\R2026b_Prerelease", "C:\Program Files\MATLAB\R2026a", "C:\Program Files\MATLAB\R2025b", "C:\Program Files\MATLAB\R2024b")) {
        if (Test-Path $cand) { $MatlabRoot = $cand; break }
    }
}
if (-not $MatlabRoot -or -not (Test-Path (Join-Path $MatlabRoot "bin\matlab.exe"))) {
    Write-Error "MATLAB not found. Set `$env:MATLAB_ROOT or install MATLAB. Tried: $MatlabRoot"
    exit 1
}
$MatlabExe = Join-Path $MatlabRoot "bin\matlab.exe"
Write-Host "MATLAB root: $MatlabRoot"
Write-Host "MATLAB exe: $MatlabExe"

# --- Locate Visual Studio ---
$VsDevCmd = $null
$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vsWhere) {
    $vsPath = & $vsWhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>$null
    if ($vsPath -and (Test-Path $vsPath)) {
        $VsDevCmd = Join-Path $vsPath "Common7\Tools\VsDevCmd.bat"
    }
}
if (-not $VsDevCmd -or -not (Test-Path $VsDevCmd)) {
    foreach ($cand in @("C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat",
                        "C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\Tools\VsDevCmd.bat",
                        "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat",
                        "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\VsDevCmd.bat")) {
        if (Test-Path $cand) { $VsDevCmd = $cand; break }
    }
}
if (-not $VsDevCmd -or -not (Test-Path $VsDevCmd)) {
    Write-Error "Visual Studio 2022 not found. Install 'Desktop development with C++' workload."
    exit 1
}
Write-Host "VsDevCmd: $VsDevCmd"

# --- Ensure cmake ---
$cmakeExe = $null
try { $cmakeExe = (Get-Command cmake -ErrorAction Stop).Source } catch {}
if (-not $cmakeExe -or -not (Test-Path $cmakeExe)) {
    $cmakeExe = "C:\Program Files\CMake\bin\cmake.exe"
}
if (-not (Test-Path $cmakeExe)) {
    Write-Host "cmake not found, trying winget install..." -ForegroundColor Yellow
    try {
        $proc = Start-Process winget -ArgumentList 'install --id Kitware.CMake -e --source winget --accept-package-agreements --accept-source-agreements' -Wait -PassThru -NoNewWindow
        if ($proc.ExitCode -eq 0) { $cmakeExe = "C:\Program Files\CMake\bin\cmake.exe" }
    } catch { Write-Host "winget failed: $_" -ForegroundColor Yellow }
}
if (-not (Test-Path $cmakeExe)) {
    # Fallback to temp download
    $tmpCmakeZip = Join-Path $env:TEMP "cmake-3.31.6.zip"
    $tmpCmakeDir = Join-Path $env:TEMP "cmake-3.31.6-windows-x86_64"
    if (-not (Test-Path (Join-Path $tmpCmakeDir "bin\cmake.exe"))) {
        Write-Host "Downloading cmake portable..." -ForegroundColor Yellow
        $url = "https://github.com/Kitware/CMake/releases/download/v3.31.6/cmake-3.31.6-windows-x86_64.zip"
        Invoke-WebRequest -Uri $url -OutFile $tmpCmakeZip -UseBasicParsing
        Expand-Archive -Path $tmpCmakeZip -DestinationPath $env:TEMP -Force
    }
    $cmakeExe = Join-Path $tmpCmakeDir "bin\cmake.exe"
}
if (-not (Test-Path $cmakeExe)) { Write-Error "cmake not found after install attempts."; exit 1 }
Write-Host "cmake: $cmakeExe"
& $cmakeExe --version | Write-Host

# --- Prepare source ---
$tmpDir = Join-Path $env:TEMP "nomad46_build"
if (Test-Path $tmpDir) { Remove-Item $tmpDir -Recurse -Force }
New-Item -ItemType Directory -Path $tmpDir | Out-Null

$srcZip = Join-Path $tmpDir "nomad-4.6.0.zip"
$srcUrl = "https://github.com/bbopt/nomad/archive/refs/tags/v.4.6.0.zip"
Write-Host "Downloading NOMAD 4.6.0 source..."
Invoke-WebRequest -Uri $srcUrl -OutFile $srcZip -UseBasicParsing
Write-Host "Extracting..."
Expand-Archive -Path $srcZip -DestinationPath $tmpDir -Force
$srcRoot = Get-ChildItem $tmpDir -Directory | Where-Object { $_.Name -like "nomad*" } | Select-Object -First 1 -ExpandProperty FullName
Write-Host "Source: $srcRoot"

$buildDir = Join-Path $srcRoot "build\release"
Write-Host "Configuring NOMAD..."
# Use a batch file to set VS env and run cmake
$batchFile = Join-Path $env:TEMP "nomad_configure.bat"
Set-Content -Path $batchFile -Value @"
@echo off
call "$VsDevCmd" -arch=amd64 >nul
cmake -DTEST_OPENMP=OFF -DBUILD_INTERFACE_MATLAB=ON -DMatlab_ROOT_DIR="$MatlabRoot" -S "$srcRoot" -B "$buildDir" -A x64
echo CMAKE_EXIT=%ERRORLEVEL%
"@
cmd /c "`"$batchFile`"" 2>&1 | Write-Host
if ($LASTEXITCODE -ne 0) {
    # Check if configure actually succeeded via exit code in output
    $out = Get-Content (Join-Path $tmpDir "nomad_configure.log") -ErrorAction SilentlyContinue
}

# Verify configure succeeded by checking build files
if (-not (Test-Path (Join-Path $buildDir "CMakeCache.txt"))) {
    Write-Error "CMake configure failed (no CMakeCache.txt). Check output above."
    exit 1
}

Write-Host "Building NOMAD (Release) - this may take 3-5 minutes..." -ForegroundColor Cyan
$batchBuild = Join-Path $env:TEMP "nomad_build.bat"
Set-Content -Path $batchBuild -Value @"
@echo off
call "$VsDevCmd" -arch=amd64 >nul
cmake --build "$buildDir" --config Release
echo BUILD_EXIT=%ERRORLEVEL%
"@
cmd /c "`"$batchBuild`"" 2>&1 | Write-Host
# Check for mex existence regardless of exit code (MSB8029 warnings cause exit 1 but mex still built)
$builtMex = Join-Path $buildDir "interfaces\Matlab_MEX\Release\nomadOpt.mexw64"
if (-not (Test-Path $builtMex)) {
    # Try alternative location (single-config)
    $builtMex = Join-Path $buildDir "interfaces\Matlab_MEX\nomadOpt.mexw64"
}
if (-not (Test-Path $builtMex)) {
    $found = Get-ChildItem $buildDir -Recurse -Filter "nomadOpt.mexw64" | Select-Object -First 1
    if ($found) { $builtMex = $found.FullName }
}
if (-not (Test-Path $builtMex)) {
    Write-Error "Built nomadOpt.mexw64 not found. Build may have failed."
    Get-ChildItem $buildDir -Recurse -Filter "*.mexw64" | Format-Table FullName | Out-String | Write-Host
    exit 1
}
Write-Host "Found MEX: $builtMex ($((Get-Item $builtMex).Length) bytes)" -ForegroundColor Green

# --- Deploy to repo ---
$destWin = Join-Path $RepoRoot "helper_methods\math\nomad\v4.6\win64"
if (-not (Test-Path $destWin)) { New-Item -ItemType Directory -Path $destWin -Force | Out-Null }
Write-Host "Deploying to $destWin..."

Copy-Item -Path $builtMex -Destination (Join-Path $destWin "nomadOpt.mexw64") -Force
Write-Host "  copied nomadOpt.mexw64"

# Copy DLLs from build
$dllMap = @{
    (Join-Path $buildDir "src\Release\nomadAlgos.dll") = "nomadAlgos.dll"
    (Join-Path $buildDir "src\Release\nomadEval.dll")  = "nomadEval.dll"
    (Join-Path $buildDir "src\Release\nomadUtils.dll") = "nomadUtils.dll"
    (Join-Path $buildDir "ext\sgtelib\Release\sgtelib.dll") = "sgtelib.dll"
    (Join-Path $buildDir "src\Release\nomad.exe") = "nomad.exe"
}
foreach ($src in $dllMap.Keys) {
    $dst = Join-Path $destWin $dllMap[$src]
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $dst -Force
        Write-Host "  copied $($dllMap[$src]) ($((Get-Item $dst).Length) bytes)"
    } else {
        Write-Host "  WARNING: $src not found, skipping" -ForegroundColor Yellow
    }
}
# Keep nomadCInterface.dll from binary release if not built (C interface disabled)
if (-not (Test-Path (Join-Path $destWin "nomadCInterface.dll"))) {
    Write-Host "  nomadCInterface.dll not built (C interface disabled), keeping existing if present" -ForegroundColor Yellow
}

Write-Host "Deployed files:" -ForegroundColor Cyan
Get-ChildItem $destWin | Format-Table Name,Length | Out-String | Write-Host

# Verify nomad version
$nomadExe = Join-Path $destWin "nomad.exe"
if (Test-Path $nomadExe) {
    Write-Host "Checking nomad version..."
    Push-Location $destWin
    try { & $nomadExe -v 2>&1 | Write-Host } finally { Pop-Location }
}

# --- MATLAB smoke test ---
if (-not $NoSmokeTest) {
    Write-Host "Running MATLAB smoke test..." -ForegroundColor Cyan
    $smokeScript = Join-Path $env:TEMP "nomad_smoke_test.m"
    Set-Content -Path $smokeScript -Value @"
try
    clear mex; clear functions; rehash toolboxcache;
    addpath(genpath(fullfile('$RepoRoot','helper_methods')));
    v46 = fullfile('$RepoRoot','helper_methods','math','nomad','v4.6','win64');
    % Prioritize v4.6 (avoid DLL hell with v4.4)
    rmpath(genpath(fullfile('$RepoRoot','helper_methods','math','nomad','v4.4')));
    addpath(v46, '-begin');
    fprintf('which nomadOpt: %s\n', which('nomadOpt'));
    obj = @(x) sum((x-3).^2);
    opts=struct('MAX_BB_EVAL','30','BB_OUTPUT_TYPE','OBJ','DISPLAY_DEGREE','0');
    [x,fval,exitflag]=nomadOpt(obj, [0 0], [0 0], [10 10], opts, []);
    fprintf('nomadOpt smoke: x=[%g %g] fval=%g exitflag=%d\n', x(1), x(2), fval, exitflag);
    if norm(x(:)' - [3 3]) < 0.5
        fprintf('SMOKE PASS\n');
    else
        fprintf('SMOKE FAIL\n');
        exit(1);
    end
catch ME
    fprintf('SMOKE ERROR: %s\n', ME.message);
    disp(getReport(ME));
    exit(1);
end
exit(0);
"@
    $smokeOut = Join-Path $env:TEMP "nomad_smoke_out.txt"
    $proc = Start-Process -FilePath $MatlabExe -ArgumentList "-batch", "run('$smokeScript')" -Wait -PassThru -NoNewWindow -RedirectStandardOutput $smokeOut -RedirectStandardError $smokeOut
    Get-Content $smokeOut | Write-Host
    if ($proc.ExitCode -eq 0) {
        Write-Host "MATLAB smoke test PASSED" -ForegroundColor Green
    } else {
        Write-Host "MATLAB smoke test FAILED (exit $($proc.ExitCode)), check $smokeOut" -ForegroundColor Red
    }
}

Write-Host "=== Done ===" -ForegroundColor Green
Write-Host "To commit: git add helper_methods\math\nomad\v4.6\win64 && git commit -m 'Add NOMAD 4.6 Windows MEX'"
Write-Host "For Linux, run on a Linux machine: ./build_nomad46_linux_mex.sh"
