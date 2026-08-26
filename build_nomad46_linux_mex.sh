#!/usr/bin/env bash
# build_nomad46_linux_mex.sh
#
# One-click builder for NOMAD 4.6.0 MATLAB MEX (nomadOpt.mexa64) on Linux.
# Mirrors the Windows build that produced helper_methods/math/nomad/v4.6/win64/nomadOpt.mexw64.
#
# Usage (on Linux, from repo root):
#   chmod +x build_nomad46_linux_mex.sh
#   ./build_nomad46_linux_mex.sh [REPO_ROOT]   # defaults to script dir
#
# Requirements:
#   - MATLAB with `matlab` on PATH or $MATLAB_ROOT set (e.g., /usr/local/MATLAB/R2024b)
#   - cmake >= 3.15
#   - GCC >= 8 or Clang >= 5
#   - Internet access to download NOMAD source (if not already cached)
#
# What it does:
#   1. Locates MATLAB
#   2. Downloads NOMAD 4.6.0 source to a temp dir (if needed)
#   3. Configures with: cmake -DTEST_OPENMP=OFF -DBUILD_INTERFACE_MATLAB=ON -DMatlab_ROOT_DIR=... -S . -B build/release
#   4. Builds: cmake --build build/release --config Release
#   5. Installs to build/release (default prefix)
#   6. Copies nomadOpt.mexa64 + libnomad*.so* + libsgtelib.so* to helper_methods/math/nomad/v4.6/linux
#   7. Verifies via `file` and `nomad -v` and a minimal MATLAB smoke test (if MATLAB available)
#
# The resulting layout matches the Windows install:
#   helper_methods/math/nomad/v4.6/linux/nomadOpt.mexa64  (MEX,  ~736k)
#   helper_methods/math/nomad/v4.6/linux/libnomadAlgos.so* etc.
#   helper_methods/math/nomad/v4.6/linux/nomad             (standalone, ELF)
#
# If you only need the standalone binaries, they are already in
# helper_methods/math/nomad/v4.6/linux/ from the binary release.
# This script is only needed to (re)build the MATLAB MEX.
#
# Exit codes: 0 on success, non-zero on error.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${1:-$SCRIPT_DIR}"

if [[ ! -d "$REPO_ROOT/helper_methods" ]]; then
    echo "ERROR: '$REPO_ROOT/helper_methods' not found. Pass repo root as first arg." >&2
    exit 1
fi

echo "=== NOMAD 4.6.0 Linux MEX Builder ==="
echo "Repo root: $REPO_ROOT"

# --- Locate MATLAB ---
if [[ -n "${MATLAB_ROOT:-}" ]]; then
    MATLAB_BIN="$MATLAB_ROOT/bin/matlab"
    MATLAB_ROOT_DIR="$MATLAB_ROOT"
elif command -v matlab >/dev/null 2>&1; then
    MATLAB_BIN="$(command -v matlab)"
    # Try to resolve MATLAB root via `matlab -batch`
    if MATLAB_ROOT_DIR="$(matlab -batch "disp(matlabroot); exit" 2>/dev/null | tail -n1 | tr -d '\r\n')"; then
        MATLAB_ROOT_DIR="$(echo "$MATLAB_ROOT_DIR" | grep -oE '/.*MATLAB.*' || echo "")"
        if [[ -z "$MATLAB_ROOT_DIR" ]]; then
            # Fallback: dirname of matlab bin
            MATLAB_ROOT_DIR="$(dirname "$(dirname "$MATLAB_BIN")")"
        fi
    else
        MATLAB_ROOT_DIR="$(dirname "$(dirname "$MATLAB_BIN")")"
    fi
else
    echo "ERROR: MATLAB not found. Set MATLAB_ROOT or ensure 'matlab' is on PATH." >&2
    exit 1
fi

# Validate MATLAB root contains extern/lib
if [[ ! -d "$MATLAB_ROOT_DIR/extern" ]]; then
    echo "WARNING: MATLAB_ROOT_DIR $MATLAB_ROOT_DIR may be incorrect (no extern/). Trying to auto-detect..." >&2
    # Try common locations
    for cand in "/usr/local/MATLAB/R202"* "/opt/MATLAB/R202"*; do
        if [[ -d "$cand/extern" ]]; then
            echo "Found MATLAB at $cand"
            MATLAB_ROOT_DIR="$cand"
            break
        fi
    done
fi

echo "MATLAB bin: $MATLAB_BIN"
echo "MATLAB root: $MATLAB_ROOT_DIR"

# --- Check cmake ---
if ! command -v cmake >/dev/null 2>&1; then
    echo "ERROR: cmake not found. Install cmake >= 3.15 (e.g., sudo apt install cmake)." >&2
    exit 1
fi
CMAKE_VER="$(cmake --version | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)"
echo "cmake: $CMAKE_VER"
# Simple version check >=3.15
CMAKE_MAJOR="$(echo "$CMAKE_VER" | cut -d. -f1)"
CMAKE_MINOR="$(echo "$CMAKE_VER" | cut -d. -f2)"
if [[ "$CMAKE_MAJOR" -lt 3 ]] || { [[ "$CMAKE_MAJOR" -eq 3 ]] && [[ "$CMAKE_MINOR" -lt 15 ]]; }; then
    echo "ERROR: cmake $CMAKE_VER is too old, need >=3.15" >&2
    exit 1
fi

# --- Check compiler ---
if command -v g++ >/dev/null 2>&1; then
    GPP_VER="$(g++ --version | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)"
    echo "g++: $GPP_VER"
    GPP_MAJOR="$(echo "$GPP_VER" | cut -d. -f1)"
    if [[ "$GPP_MAJOR" -lt 8 ]]; then
        echo "WARNING: g++ $GPP_VER < 8 may not be supported by NOMAD." >&2
    fi
elif command -v clang++ >/dev/null 2>&1; then
    echo "clang++: $(clang++ --version | head -n1)"
else
    echo "ERROR: No C++ compiler found (need g++ >=8 or clang++ >=5)." >&2
    exit 1
fi

# --- Prepare source ---
SRC_TMP="$(mktemp -d)"
trap 'rm -rf "$SRC_TMP"' EXIT
SRC_ZIP="$SRC_TMP/nomad-4.6.0.zip"
SRC_DIR="$SRC_TMP/nomad-v.4.6.0"

if [[ -n "${NOMAD_SRC_DIR:-}" && -d "$NOMAD_SRC_DIR" ]]; then
    echo "Using existing source at $NOMAD_SRC_DIR"
    SRC_DIR="$NOMAD_SRC_DIR"
else
    echo "Downloading NOMAD 4.6.0 source..."
    SRC_URL="https://github.com/bbopt/nomad/archive/refs/tags/v.4.6.0.zip"
    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$SRC_ZIP" "$SRC_URL"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$SRC_ZIP" "$SRC_URL"
    else
        echo "ERROR: Need curl or wget to download source." >&2
        exit 1
    fi
    echo "Extracting..."
    unzip -q "$SRC_ZIP" -d "$SRC_TMP"
    # The extracted folder is nomad-v.4.6.0 (note the dot)
    if [[ ! -d "$SRC_DIR" ]]; then
        # Find the extracted dir
        SRC_DIR="$(find "$SRC_TMP" -maxdepth 1 -type d -name "nomad*" | head -n1)"
    fi
    echo "Source: $SRC_DIR"
fi

# --- Configure ---
BUILD_DIR="$SRC_DIR/build/release"
echo "Configuring NOMAD (TEST_OPENMP=OFF, BUILD_INTERFACE_MATLAB=ON)..."
# Clean previous build if exists
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# NOMAD's CMake warns if build dir is under /tmp (MSB8029 on Windows, harmless on Linux but we avoid it by using SRC_DIR/build)
cmake -DTEST_OPENMP=OFF \
      -DBUILD_INTERFACE_MATLAB=ON \
      -DMatlab_ROOT_DIR="$MATLAB_ROOT_DIR" \
      -DCMAKE_BUILD_TYPE=Release \
      -S "$SRC_DIR" \
      -B "$BUILD_DIR"

# --- Build ---
echo "Building NOMAD (this may take a few minutes)..."
cmake --build "$BUILD_DIR" --config Release -j"$(nproc 2>/dev/null || echo 4)"

# --- Install ---
echo "Installing to $BUILD_DIR (prefix)..."
cmake --install "$BUILD_DIR" --config Release || cmake --install "$BUILD_DIR"

# --- Locate artifacts ---
echo "Locating built MEX and libs..."

# Find mex
MEX_CANDIDATES=(
    "$BUILD_DIR/interfaces/Matlab_MEX/nomadOpt.mexa64"
    "$BUILD_DIR/interfaces/Matlab_MEX/Release/nomadOpt.mexa64"
    "$BUILD_DIR/lib/nomadOpt.mexa64"
    "$BUILD_DIR/lib64/nomadOpt.mexa64"
)
MEX_SRC=""
for cand in "${MEX_CANDIDATES[@]}"; do
    if [[ -f "$cand" ]]; then
        MEX_SRC="$cand"
        break
    fi
done
if [[ -z "$MEX_SRC" ]]; then
    # Search recursively
    MEX_SRC="$(find "$BUILD_DIR" -name "nomadOpt.mexa64" | head -n1 || true)"
fi
if [[ -z "$MEX_SRC" || ! -f "$MEX_SRC" ]]; then
    echo "ERROR: Built nomadOpt.mexa64 not found. Searched:"
    printf '  %s\n' "${MEX_CANDIDATES[@]}"
    find "$BUILD_DIR" -name "*.mexa64" | head -n20 || true
    exit 1
fi
echo "Found MEX: $MEX_SRC ($(du -h "$MEX_SRC" | cut -f1))"

# Find libs (shared)
LIB_SRC_DIR=""
for d in "$BUILD_DIR/lib" "$BUILD_DIR/lib64" "$BUILD_DIR/src" "$BUILD_DIR/src/Release" "$BUILD_DIR/ext/sgtelib" "$BUILD_DIR/ext/sgtelib/Release"; do
    if [[ -d "$d" ]]; then
        if ls "$d"/libnomad*.so* >/dev/null 2>&1; then
            LIB_SRC_DIR="$d"
            break
        fi
    fi
done
# Fallback: find libnomadAlgos.so.4.6.0
if [[ -z "$LIB_SRC_DIR" ]]; then
    LIB_ALGOS="$(find "$BUILD_DIR" -name "libnomadAlgos.so.4.6.0" | head -n1 || true)"
    if [[ -n "$LIB_ALGOS" ]]; then
        LIB_SRC_DIR="$(dirname "$LIB_ALGOS")"
    fi
fi
echo "Lib source dir: ${LIB_SRC_DIR:-<not found, will search>}"

# --- Deploy to repo ---
DEST_LINUX="$REPO_ROOT/helper_methods/math/nomad/v4.6/linux"
mkdir -p "$DEST_LINUX"
echo "Deploying to $DEST_LINUX..."

# Copy MEX
cp -v "$MEX_SRC" "$DEST_LINUX/nomadOpt.mexa64"
chmod 644 "$DEST_LINUX/nomadOpt.mexa64"

# Copy shared libs - try to find all versioned .so
# Prefer the installed lib dir (BUILD_DIR/lib)
if [[ -d "$BUILD_DIR/lib" ]]; then
    echo "Copying libs from $BUILD_DIR/lib..."
    cp -v "$BUILD_DIR/lib"/libnomad*.so* "$DEST_LINUX"/ 2>/dev/null || true
    cp -v "$BUILD_DIR/lib"/libsgtelib.so* "$DEST_LINUX"/ 2>/dev/null || true
fi
if [[ -d "$BUILD_DIR/lib64" ]]; then
    cp -v "$BUILD_DIR/lib64"/libnomad*.so* "$DEST_LINUX"/ 2>/dev/null || true
    cp -v "$BUILD_DIR/lib64"/libsgtelib.so* "$DEST_LINUX"/ 2>/dev/null || true
fi
# Also copy from src/Release if needed (for the .so built there, though install should have copied)
# Find any missing .so.4.6.0 and copy
for lib in libnomadAlgos.so.4.6.0 libnomadEval.so.4.6.0 libnomadUtils.so.4.6.0 libsgtelib.so.2.0.5 libnomadCInterface.so.4.6.0; do
    if [[ ! -f "$DEST_LINUX/$lib" ]]; then
        found="$(find "$BUILD_DIR" -name "$lib" | head -n1 || true)"
        if [[ -n "$found" ]]; then
            cp -v "$found" "$DEST_LINUX/"
        fi
    fi
done
# Ensure symlinks / copies for SONAME chain (as done in Windows install)
# The binary release used copies; we create the same chain as after manual install:
# libnomadAlgos.so -> libnomadAlgos.so.4.6 -> libnomadAlgos.so.4.6.0
# On Linux, create symlinks (more efficient than copies)
pushd "$DEST_LINUX" >/dev/null
for base in libnomadAlgos libnomadEval libnomadUtils; do
    if [[ -f "${base}.so.4.6.0" ]]; then
        ln -sf "${base}.so.4.6.0" "${base}.so.4.6" 2>/dev/null || cp -f "${base}.so.4.6.0" "${base}.so.4.6"
        ln -sf "${base}.so.4.6" "${base}.so" 2>/dev/null || cp -f "${base}.so.4.6.0" "${base}.so"
        echo "Linked $base.so -> $base.so.4.6 -> $base.so.4.6.0"
    fi
done
if [[ -f "libsgtelib.so.2.0.5" ]]; then
    ln -sf "libsgtelib.so.2.0.5" "libsgtelib.so.2.0" 2>/dev/null || cp -f "libsgtelib.so.2.0.5" "libsgtelib.so.2.0"
    ln -sf "libsgtelib.so.2.0" "libsgtelib.so" 2>/dev/null || cp -f "libsgtelib.so.2.0.5" "libsgtelib.so"
fi
if [[ -f "libnomadCInterface.so.4.6.0" ]]; then
    ln -sf "libnomadCInterface.so.4.6.0" "libnomadCInterface.so.4.6" 2>/dev/null || cp -f "libnomadCInterface.so.4.6.0" "libnomadCInterface.so.4.6"
    ln -sf "libnomadCInterface.so.4.6" "libnomadCInterface.so" 2>/dev/null || cp -f "libnomadCInterface.so.4.6.0" "libnomadCInterface.so"
fi
# Also handle nomad executable symlink
if [[ -f "nomad-4.6.0" && ! -f "nomad" ]]; then
    ln -sf "nomad-4.6.0" "nomad" 2>/dev/null || cp -f "nomad-4.6.0" "nomad"
fi
popd >/dev/null

# Also copy nomad standalone if not present
if [[ ! -f "$DEST_LINUX/nomad-4.6.0" ]]; then
    NOMAD_BIN="$(find "$BUILD_DIR" -name "nomad" -type f | head -n1 || true)"
    if [[ -n "$NOMAD_BIN" && -f "$NOMAD_BIN" ]]; then
        cp -v "$NOMAD_BIN" "$DEST_LINUX/nomad-4.6.0"
        chmod +x "$DEST_LINUX/nomad-4.6.0"
        ln -sf "nomad-4.6.0" "$DEST_LINUX/nomad" 2>/dev/null || cp -f "$DEST_LINUX/nomad-4.6.0" "$DEST_LINUX/nomad"
    fi
fi

echo "=== Deployed files ==="
ls -lh "$DEST_LINUX" | cat
# Verify MEX is ELF and has correct header
if command -v file >/dev/null 2>&1; then
    file "$DEST_LINUX/nomadOpt.mexa64" || true
fi
# Verify standalone version
if [[ -x "$DEST_LINUX/nomad" ]]; then
    echo "Checking nomad version..."
    LD_LIBRARY_PATH="$DEST_LINUX:${LD_LIBRARY_PATH:-}" "$DEST_LINUX/nomad" -v || true
fi

# --- Optional MATLAB smoke test ---
if command -v matlab >/dev/null 2>&1; then
    echo "Running MATLAB smoke test (may take 10s)..."
    SMOKE_TMP="$(mktemp /tmp/nomad_smoke_XXXX.m)"
    cat > "$SMOKE_TMP" <<'MATLAB_EOF'
try
    addpath(genpath('helper_methods'));
    % Prioritize v4.6
    v46 = fullfile(pwd,'helper_methods','math','nomad','v4.6','linux');
    addpath(v46, '-begin');
    fprintf('which nomadOpt: %s\n', which('nomadOpt'));
    obj = @(x) sum((x-3).^2);
    opts=struct('MAX_BB_EVAL','30','BB_OUTPUT_TYPE','OBJ','DISPLAY_DEGREE','0');
    [x,fval,exitflag]=nomadOpt(obj, [0 0], [0 0], [10 10], opts, []);
    fprintf('nomadOpt smoke: x=[%g %g] fval=%g exitflag=%d\n', x(1), x(2), fval, exitflag);
    if norm(x(:)' - [3 3]) < 0.5
        fprintf('SMOKE PASS\n');
        exit(0);
    else
        fprintf('SMOKE FAIL\n');
        exit(1);
    end
catch ME
    fprintf('SMOKE ERROR: %s\n', ME.message);
    disp(getReport(ME));
    exit(1);
end
MATLAB_EOF
    # Run with a timeout
    if timeout 30 matlab -batch "run('$SMOKE_TMP')" 2>&1 | tail -n 50; then
        echo "MATLAB smoke test passed"
    else
        echo "MATLAB smoke test failed or timed out (check manually)"
    fi
    rm -f "$SMOKE_TMP"
else
    echo "MATLAB not on PATH, skipping smoke test. Run manually:"
    echo "  matlab -batch \"addpath(genpath('helper_methods')); addpath('helper_methods/math/nomad/v4.6/linux','-begin'); obj=@(x)sum((x-3).^2); [x,fval]=nomadOpt(obj,[0 0],[0 0],[10 10],struct('MAX_BB_EVAL','30','BB_OUTPUT_TYPE','OBJ'),[]); disp(x)\""
fi

echo "=== Done ==="
echo "If you see 'SMOKE PASS' or files in $DEST_LINUX, the install succeeded."
echo "Commit the new files: git add helper_methods/math/nomad/v4.6/linux && git commit -m 'Add NOMAD 4.6 Linux MEX'"
