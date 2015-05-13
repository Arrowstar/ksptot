@echo off
set MATLAB=C:\PROGRA~2\MATLAB\R2013a
set MATLAB_ARCH=win32
set MATLAB_BIN="C:\Program Files (x86)\MATLAB\R2013a\bin"
set ENTRYPOINT=mexFunction
set OUTDIR=.\
set LIB_NAME=AngleZero2Pi_mex
set MEX_NAME=AngleZero2Pi_mex
set MEX_EXT=.mexw32
call mexopts.bat
echo # Make settings for AngleZero2Pi > AngleZero2Pi_mex.mki
echo COMPILER=%COMPILER%>> AngleZero2Pi_mex.mki
echo COMPFLAGS=%COMPFLAGS%>> AngleZero2Pi_mex.mki
echo OPTIMFLAGS=%OPTIMFLAGS%>> AngleZero2Pi_mex.mki
echo DEBUGFLAGS=%DEBUGFLAGS%>> AngleZero2Pi_mex.mki
echo LINKER=%LINKER%>> AngleZero2Pi_mex.mki
echo LINKFLAGS=%LINKFLAGS%>> AngleZero2Pi_mex.mki
echo LINKOPTIMFLAGS=%LINKOPTIMFLAGS%>> AngleZero2Pi_mex.mki
echo LINKDEBUGFLAGS=%LINKDEBUGFLAGS%>> AngleZero2Pi_mex.mki
echo MATLAB_ARCH=%MATLAB_ARCH%>> AngleZero2Pi_mex.mki
echo BORLAND=%BORLAND%>> AngleZero2Pi_mex.mki
echo OMPFLAGS= >> AngleZero2Pi_mex.mki
echo OMPLINKFLAGS= >> AngleZero2Pi_mex.mki
echo EMC_COMPILER=lcc>> AngleZero2Pi_mex.mki
echo EMC_CONFIG=optim>> AngleZero2Pi_mex.mki
"C:\Program Files (x86)\MATLAB\R2013a\bin\win32\gmake" -B -f AngleZero2Pi_mex.mk
