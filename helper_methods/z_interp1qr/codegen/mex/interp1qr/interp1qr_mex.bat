@echo off
set MATLAB=C:\PROGRA~1\MATLAB\R2017b
set MATLAB_ARCH=win64
set MATLAB_BIN="C:\Program Files\MATLAB\R2017b\bin"
set ENTRYPOINT=mexFunction
set OUTDIR=.\
set LIB_NAME=interp1qr_mex
set MEX_NAME=interp1qr_mex
set MEX_EXT=.mexw64
call setEnv.bat
echo # Make settings for interp1qr > interp1qr_mex.mki
echo CC=%COMPILER%>> interp1qr_mex.mki
echo CXX=%CXXCOMPILER%>> interp1qr_mex.mki
echo CFLAGS=%COMPFLAGS%>> interp1qr_mex.mki
echo CXXFLAGS=%CXXCOMPFLAGS%>> interp1qr_mex.mki
echo OPTIMFLAGS=%OPTIMFLAGS%>> interp1qr_mex.mki
echo DEBUGFLAGS=%DEBUGFLAGS%>> interp1qr_mex.mki
echo LINKER=%LINKER%>> interp1qr_mex.mki
echo LINKFLAGS=%LINKFLAGS%>> interp1qr_mex.mki
echo LINKOPTIMFLAGS=%LINKOPTIMFLAGS%>> interp1qr_mex.mki
echo LINKDEBUGFLAGS=%LINKDEBUGFLAGS%>> interp1qr_mex.mki
echo MATLAB_ARCH=%MATLAB_ARCH%>> interp1qr_mex.mki
echo OMPFLAGS= >> interp1qr_mex.mki
echo OMPLINKFLAGS= >> interp1qr_mex.mki
echo EMC_COMPILER=mingw64>> interp1qr_mex.mki
echo EMC_CONFIG=optim>> interp1qr_mex.mki
"C:\Program Files\MATLAB\R2017b\bin\win64\gmake" -B -f interp1qr_mex.mk
