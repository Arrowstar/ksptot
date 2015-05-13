@echo off
set MATLAB=C:\PROGRA~1\MATLAB\R2014b
set MATLAB_ARCH=win64
set MATLAB_BIN="C:\Program Files\MATLAB\R2014b\bin"
set ENTRYPOINT=mexFunction
set OUTDIR=.\
set LIB_NAME=lambert_mex
set MEX_NAME=lambert_mex
set MEX_EXT=.mexw64
call setEnv.bat
echo # Make settings for lambert > lambert_mex.mki
echo COMPILER=%COMPILER%>> lambert_mex.mki
echo COMPFLAGS=%COMPFLAGS%>> lambert_mex.mki
echo OPTIMFLAGS=%OPTIMFLAGS%>> lambert_mex.mki
echo DEBUGFLAGS=%DEBUGFLAGS%>> lambert_mex.mki
echo LINKER=%LINKER%>> lambert_mex.mki
echo LINKFLAGS=%LINKFLAGS%>> lambert_mex.mki
echo LINKOPTIMFLAGS=%LINKOPTIMFLAGS%>> lambert_mex.mki
echo LINKDEBUGFLAGS=%LINKDEBUGFLAGS%>> lambert_mex.mki
echo MATLAB_ARCH=%MATLAB_ARCH%>> lambert_mex.mki
echo BORLAND=%BORLAND%>> lambert_mex.mki
echo OMPFLAGS= >> lambert_mex.mki
echo OMPLINKFLAGS= >> lambert_mex.mki
echo EMC_COMPILER=msvcsdk>> lambert_mex.mki
echo EMC_CONFIG=optim>> lambert_mex.mki
"C:\Program Files\MATLAB\R2014b\bin\win64\gmake" -B -f lambert_mex.mk
