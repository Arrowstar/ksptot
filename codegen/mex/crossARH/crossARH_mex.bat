@echo off
set MATLAB=C:\PROGRA~2\MATLAB\R2013a
set MATLAB_ARCH=win32
set MATLAB_BIN="C:\Program Files (x86)\MATLAB\R2013a\bin"
set ENTRYPOINT=mexFunction
set OUTDIR=.\
set LIB_NAME=crossARH_mex
set MEX_NAME=crossARH_mex
set MEX_EXT=.mexw32
call mexopts.bat
echo # Make settings for crossARH > crossARH_mex.mki
echo COMPILER=%COMPILER%>> crossARH_mex.mki
echo COMPFLAGS=%COMPFLAGS%>> crossARH_mex.mki
echo OPTIMFLAGS=%OPTIMFLAGS%>> crossARH_mex.mki
echo DEBUGFLAGS=%DEBUGFLAGS%>> crossARH_mex.mki
echo LINKER=%LINKER%>> crossARH_mex.mki
echo LINKFLAGS=%LINKFLAGS%>> crossARH_mex.mki
echo LINKOPTIMFLAGS=%LINKOPTIMFLAGS%>> crossARH_mex.mki
echo LINKDEBUGFLAGS=%LINKDEBUGFLAGS%>> crossARH_mex.mki
echo MATLAB_ARCH=%MATLAB_ARCH%>> crossARH_mex.mki
echo BORLAND=%BORLAND%>> crossARH_mex.mki
echo OMPFLAGS= >> crossARH_mex.mki
echo OMPLINKFLAGS= >> crossARH_mex.mki
echo EMC_COMPILER=lcc>> crossARH_mex.mki
echo EMC_CONFIG=optim>> crossARH_mex.mki
"C:\Program Files (x86)\MATLAB\R2013a\bin\win32\gmake" -B -f crossARH_mex.mk
