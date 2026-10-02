SPICE kernels vendored for SolarSystemRotationPckTest (tests/unit_tests).
Sources (NASA NAIF, public domain data):
  naif0012.tls  - leapseconds kernel
                  https://naif.jpl.nasa.gov/pub/naif/generic_kernels/lsk/naif0012.tls
  pck00011.tpc  - planetary constants / IAU rotation models (Archinal et al. 2018,
                  Celest. Mech. Dyn. Astr. 130:22)
                  https://naif.jpl.nasa.gov/pub/naif/generic_kernels/pck/pck00011.tpc
The test also needs the MICE MATLAB toolkit (mice.mexw64 + cspice_*.m), which is
NOT vendored here; install it once from
  https://naif.jpl.nasa.gov/naif/toolkit_MATLAB_PC_Windows_VisualC_MATLAB9.x_64bit.html
and place it at C:\spice (mex at C:\spice\mice\lib, M-files at C:\spice\mice\src\mice).
If MICE is absent the rotation tests are skipped (assumption) rather than failed.
