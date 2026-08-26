# build_nomad46_wsl.ps1
# One-click helper to build the NOMAD 4.6 Linux MEX via WSL from Windows.
#
# Usage (from PowerShell, in repo root):
#   powershell -ExecutionPolicy Bypass -File .\build_nomad46_wsl.ps1
#   # with custom distro or repo path:
#   .\build_nomad46_wsl.ps1 -Distro Ubuntu-24.04 -RepoRoot "C:\path\to\tot"
#
# What it does:
#   1. Checks if WSL is installed; if not, prints instructions to install (requires admin/reboot)
#   2. Ensures the requested Linux distro is available (installs Ubuntu-24.04 if missing)
#   3. Translates the Windows repo path to WSL (/mnt/c/...) and runs:
#        chmod +x build_nomad46_linux_mex.sh && ./build_nomad46_linux_mex.sh
#      inside WSL with the same MATLAB detection logic as the native Linux script.
#
# Requirements for the Linux MEX:
#   - WSL2 with a distro (Ubuntu 22.04/24.04 recommended)
#   - MATLAB for *Linux* installed inside that distro (e.g., /usr/local/MATLAB/R2024b)
#     OR MATLAB on Windows can be reused only for the standalone binaries, which are already
#     installed (helper_methods/math/nomad/v4.6/linux/nomad). The MEX itself *must* be built
#     with a Linux MATLAB, so if you do not have MATLAB for Linux, the script will still
#     verify the standalone binaries but skip the MEX smoke test.
#
# If you only need the standalone Linux binaries, they are already present from
# build_nomad46_linux_mex.sh's binary-release step; no WSL build is needed.
#
# For a native Linux machine (no WSL), just run:
#   chmod +x build_nomad46_linux_mex.sh && ./build_nomad46_linux_mex.sh

param(
    [string]$Distro = "Ubuntu-24.04",
    [string]$RepoRoot = $null,
    [string]$MatlabRoot = $null
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $RepoRoot) { $RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not (Test-Path (Join-Path $RepoRoot "helper_methods"))) {
    Write-Error "Repo root not found at $RepoRoot"
    exit 1
}

Write-Host "=== NOMAD 4.6 WSL Linux MEX Builder ===" -ForegroundColor Cyan
Write-Host "Repo root (Windows): $RepoRoot"
Write-Host "WSL distro: $Distro"

# --- Check WSL is installed ---
$wslAvailable = $false
try {
    $null = Get-Command wsl -ErrorAction Stop
    $wslVersion = wsl --version 2>&1 | Out-String
    # If wsl --version says "not installed", it will be in stderr
    if ($wslVersion -match "not installed") {
        Write-Host "WSL is not installed." -ForegroundColor Yellow
    } else {
        $wslAvailable = $true
        Write-Host "WSL available: $wslVersion" -ForegroundColor Green
    }
} catch {
    Write-Host "WSL not found in PATH." -ForegroundColor Yellow
}

if (-not $wslAvailable) {
    Write-Host @"
WSL is not installed on this machine (requires admin + reboot).

To install WSL (one-time, admin PowerShell):
  wsl --install -d $Distro
  # or: wsl --install  (defaults to Ubuntu)
Then reboot, launch Ubuntu from Start menu to create a user, then:

Inside WSL (Ubuntu), install prerequisites:
  sudo apt update && sudo apt install -y cmake g++ unzip curl wget

If you have MATLAB for Linux, install it inside WSL:
  # Example: mount Windows MATLAB ISO or copy installer to WSL
  # sudo mkdir -p /usr/local/MATLAB/R2024b && sudo ./install -mode silent -agreeToLicense yes -destinationFolder /usr/local/MATLAB/R2024b

Then from Windows, re-run this script, or from WSL directly:
  cd /mnt/c/Users/aharden/OneDrive\ -\ NASA/Documents/MATLAB/tot
  chmod +x build_nomad46_linux_mex.sh
  ./build_nomad46_linux_mex.sh
  # or with explicit MATLAB:
  MATLAB_ROOT=/usr/local/MATLAB/R2024b ./build_nomad46_linux_mex.sh

Standalone Linux binaries (nomad, libnomad*.so) are already installed in
helper_methods/math/nomad/v4.6/linux/ from the binary release, so you can use
LVD on Linux without rebuilding. Only the MATLAB MEX (nomadOpt.mexa64) needs this step.
"@ -ForegroundColor Yellow
    exit 0
}

# --- Check distro exists ---
$distros = wsl --list --quiet 2>&1 | Out-String
if ($distros -notmatch [regex]::Escape($Distro)) {
    Write-Host "Distro $Distro not found. Available:" -ForegroundColor Yellow
    wsl --list --verbose 2>&1 | Write-Host
    Write-Host "Installing $Distro (this may take a few minutes)..." -ForegroundColor Cyan
    wsl --install -d $Distro --no-launch 2>&1 | Write-Host
    Write-Host "Please launch $Distro from Start menu once to finish setup, then re-run this script." -ForegroundColor Yellow
    exit 0
}

# --- Translate Windows path to WSL (/mnt/c/...) ---
# Use wslpath if available
$wslRepoPath = $null
try {
    $wslRepoPath = wsl -d $Distro -- wslpath -a "$RepoRoot" 2>&1 | Out-String
    $wslRepoPath = $wslRepoPath.Trim()
} catch {}
if (-not $wslRepoPath -or $wslRepoPath -match "not found") {
    # Manual translation: C:\Users\... -> /mnt/c/Users/...
    $wslRepoPath = $RepoRoot -replace '^([A-Za-z]):', '/mnt/$1' -replace '\\', '/'
    $wslRepoPath = $wslRepoPath.ToLower().Replace('/mnt/c', '/mnt/c') # keep drive lower
    # More robust: lower only drive letter
    if ($RepoRoot -match '^([A-Za-z]):') { $drive = $Matches[1].ToLower(); $wslRepoPath = "/mnt/$drive" + $RepoRoot.Substring(2).Replace('\','/') }
}
Write-Host "WSL repo path: $wslRepoPath"

# --- Ensure script is executable inside WSL ---
wsl -d $Distro -- bash -c "chmod +x '$wslRepoPath/build_nomad46_linux_mex.sh' && ls -l '$wslRepoPath/build_nomad46_linux_mex.sh'" 2>&1 | Write-Host

# --- Run the Linux builder inside WSL ---
$envArg = ""
if ($MatlabRoot) {
    # Translate Windows MATLAB path to WSL if it looks like Windows
    if ($MatlabRoot -match '^[A-Za-z]:') {
        $wslMatlabRoot = $MatlabRoot -replace '^([A-Za-z]):', '/mnt/$1' -replace '\\', '/'
        if ($MatlabRoot -match '^([A-Za-z]):') { $d=$Matches[1].ToLower(); $wslMatlabRoot="/mnt/$d"+$MatlabRoot.Substring(2).Replace('\','/') }
        $envArg = "MATLAB_ROOT=`"$wslMatlabRoot`" "
    } else {
        $envArg = "MATLAB_ROOT=`"$MatlabRoot`" "
    }
}
$cmd = "cd `"$wslRepoPath`" && ${envArg}./build_nomad46_linux_mex.sh"
Write-Host "Running inside WSL: $cmd" -ForegroundColor Cyan
wsl -d $Distro -- bash -c $cmd 2>&1 | Write-Host

Write-Host "=== WSL build finished ===" -ForegroundColor Green
Write-Host "Check: ls helper_methods/math/nomad/v4.6/linux/nomadOpt.mexa64"
Write-Host "Test:  wsl -d $Distro -- bash -c 'file $wslRepoPath/helper_methods/math/nomad/v4.6/linux/nomadOpt.mexa64'"
