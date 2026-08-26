NOMAD 4.6.0 Windows binaries - KSPTOT installation
===================================================
Source: https://github.com/bbopt/nomad/releases/tag/v.4.6.0 (windows-latest.zip) + built from source via build_nomad46_win_mex.ps1
Date installed: 2026-08-26
Build host: Windows 11, Visual Studio 2022 (MSVC 19.44), CMake 4.4.2, MATLAB R2026b Prerelease
Contents:
  nomad.exe (29184) - standalone, 
omad.exe -v => Version 4.6.0 Release. Not using OpenMP. Using SGTELIB.
  nomadAlgos.dll (2738688) - built from source (was 4163584 in binary release)
  nomadEval.dll (561152)   - built from source (was 1079808)
  nomadUtils.dll (1244160) - built from source (was 2303488)
  sgtelib.dll (531968)     - built from source (was 515072)
  nomadCInterface.dll (93696) - from binary release (C interface, not built)
  nomadOpt.mexw64 (74240)  - MATLAB MEX, built via cmake -DTEST_OPENMP=OFF -DBUILD_INTERFACE_MATLAB=ON

To rebuild (one-click, from repo root):
  powershell -ExecutionPolicy Bypass -File .\build_nomad46_win_mex.ps1

The MEX was verified to solve a 2-D paraboloid (x=[3 3] fval=0) via tests/unit_tests/NomadV46BinaryTest.m:226.

Note on DLL hell: Both v4.4 and v4.6 use the same DLL names (nomadAlgos.dll etc.) but different versions (NOMAD_4_4 vs NOMAD_4_6).
MATLAB must have only one version on its path at a time. The test and build scripts handle this by clearing mex and prioritizing v4.6:
  clear mex; rmpath(genpath('helper_methods/math/nomad/v4.4')); addpath('helper_methods/math/nomad/v4.6/win64','-begin')

For Linux, run on a Linux machine:
  chmod +x build_nomad46_linux_mex.sh
  ./build_nomad46_linux_mex.sh

See helper_methods/math/nomad/v4.6/linux/README_NOMAD4.6.txt for Linux details.
