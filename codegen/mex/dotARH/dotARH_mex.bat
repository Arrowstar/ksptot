@echo off
set MATLAB=C:\PROGRA~2\MATLAB\R2013a
set MATLAB_ARCH=win32
set MATLAB_BIN="C:\Program Files (x86)\MATLAB\R2013a\bin"
set ENTRYPOINT=mexFunction
set OUTDIR=.\
set LIB_NAME=dotARH_mex
set MEX_NAME=dotARH_mex
set MEX_EXT=.mexw32
call mexopts.bat
echo # Make settings for dotARH > dotARH_mex.mki
echo COMPILER=%COMPILER%>> dotARH_mex.mki
echo COMPFLAGS=%COMPFLAGS%>> dotARH_mex.mki
echo OPTIMFLAGS=%OPTIMFLAGS%>> dotARH_mex.mki
echo DEBUGFLAGS=%DEBUGFLAGS%>> dotARH_mex.mki
echo LINKER=%LINKER%>> dotARH_mex.mki
echo LINKFLAGS=%LINKFLAGS%>> dotARH_mex.mki
echo LINKOPTIMFLAGS=%LINKOPTIMFLAGS%>> dotARH_mex.mki
echo LINKDEBUGFLAGS=%LINKDEBUGFLAGS%>> dotARH_mex.mki
echo MATLAB_ARCH=%MATLAB_ARCH%>> dotARH_mex.mki
echo BORLAND=%BORLAND%>> dotARH_mex.mki
echo OMPFLAGS= >> dotARH_mex.mki
echo OMPLINKFLAGS= >> dotARH_mex.mki
echo EMC_COMPILER=lcc>> dotARH_mex.mki
echo EMC_CONFIG=optim>> dotARH_mex.mki
"C:\Program Files (x86)\MATLAB\R2013a\bin\win32\gmake" -B -f dotARH_mex.mk
