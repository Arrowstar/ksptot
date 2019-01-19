@echo off
set MATLAB=C:\PROGRA~1\MATLAB\R2017b
set MATLAB_ARCH=win64
set MATLAB_BIN="C:\Program Files\MATLAB\R2017b\bin"
set ENTRYPOINT=mexFunction
set OUTDIR=.\
set LIB_NAME=lambert_mex
set MEX_NAME=lambert_mex
set MEX_EXT=.mexw64
call setEnv.bat
echo # Make settings for lambert > lambert_mex.mki
echo CC=%COMPILER%>> lambert_mex.mki
echo CXX=%CXXCOMPILER%>> lambert_mex.mki
echo CFLAGS=%COMPFLAGS%>> lambert_mex.mki
echo CXXFLAGS=%CXXCOMPFLAGS%>> lambert_mex.mki
echo OPTIMFLAGS=%OPTIMFLAGS%>> lambert_mex.mki
echo DEBUGFLAGS=%DEBUGFLAGS%>> lambert_mex.mki
echo LINKER=%LINKER%>> lambert_mex.mki
echo LINKFLAGS=%LINKFLAGS%>> lambert_mex.mki
echo LINKOPTIMFLAGS=%LINKOPTIMFLAGS%>> lambert_mex.mki
echo LINKDEBUGFLAGS=%LINKDEBUGFLAGS%>> lambert_mex.mki
echo MATLAB_ARCH=%MATLAB_ARCH%>> lambert_mex.mki
echo OMPFLAGS= >> lambert_mex.mki
echo OMPLINKFLAGS= >> lambert_mex.mki
echo EMC_COMPILER=mingw64>> lambert_mex.mki
echo EMC_CONFIG=optim>> lambert_mex.mki
"C:\Program Files\MATLAB\R2017b\bin\win64\gmake" -B -f lambert_mex.mk
