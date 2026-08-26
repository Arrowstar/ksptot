NOMAD 4.6.0 Linux binaries - KSPTOT installation
================================================
Source: https://github.com/bbopt/nomad/releases/tag/v.4.6.0 (ubuntu-latest.zip)
Date installed: 2026-08-26 (binaries) + pending MEX build via build_nomad46_linux_mex.sh

Current contents (from binary release, 2026-08-26):
  libnomadAlgos.so.4.6.0 (4949040) + symlinks libnomadAlgos.so.4.6 + libnomadAlgos.so
  libnomadEval.so.4.6.0 (762192)   + symlinks
  libnomadUtils.so.4.6.0 (1799168) + symlinks
  libsgtelib.so.2.0.5 (818912)     + symlinks libsgtelib.so.2.0 + libsgtelib.so
  libnomadCInterface.so.4.6.0 (257144) + symlinks (new in 4.6)
  nomad-4.6.0 (40688) + symlink nomad -> nomad-4.6.0 (ELF, 
omad -v => Version 4.6.0)

MATLAB MEX (nomadOpt.mexa64) is NOT in the binary release.
To build on Linux (one-click, from repo root):
  chmod +x build_nomad46_linux_mex.sh
  ./build_nomad46_linux_mex.sh
  # Or with custom MATLAB: MATLAB_ROOT=/usr/local/MATLAB/R2024b ./build_nomad46_linux_mex.sh

Requirements: MATLAB, cmake >=3.15, g++ >=8 or clang++ >=5
The script will:
  - Download NOMAD 4.6.0 source
  - cmake -DTEST_OPENMP=OFF -DBUILD_INTERFACE_MATLAB=ON -DMatlab_ROOT_DIR=\ -S . -B build/release
  - cmake --build build/release --config Release
  - cmake --install build/release
  - Copy nomadOpt.mexa64 + libs to helper_methods/math/nomad/v4.6/linux

After building, verify:
  file helper_methods/math/nomad/v4.6/linux/nomadOpt.mexa64  # should be ELF
  matlab -batch "addpath(genpath('helper_methods')); addpath('helper_methods/math/nomad/v4.6/linux','-begin'); obj=@(x)sum((x-3).^2); [x,fval]=nomadOpt(obj,[0 0],[0 0],[10 10],struct('MAX_BB_EVAL','30','BB_OUTPUT_TYPE','OBJ'),[]); disp(x)"

One-click Windows build (already done on this host):
  powershell -ExecutionPolicy Bypass -File build_nomad46_win_mex.ps1
  -> helper_methods/math/nomad/v4.6/win64/nomadOpt.mexw64 (74240)

Test: matlab -batch "ksptotRunTests('NomadV46BinaryTest')"
