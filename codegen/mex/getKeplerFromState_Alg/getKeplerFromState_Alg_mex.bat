@echo off
set MATLAB=C:\PROGRA~1\MATLAB\R2014b
set MATLAB_ARCH=win64
set MATLAB_BIN="C:\Program Files\MATLAB\R2014b\bin"
set ENTRYPOINT=mexFunction
set OUTDIR=.\
set LIB_NAME=getKeplerFromState_Alg_mex
set MEX_NAME=getKeplerFromState_Alg_mex
set MEX_EXT=.mexw64
call setEnv.bat
echo # Make settings for getKeplerFromState_Alg > getKeplerFromState_Alg_mex.mki
echo COMPILER=%COMPILER%>> getKeplerFromState_Alg_mex.mki
echo COMPFLAGS=%COMPFLAGS%>> getKeplerFromState_Alg_mex.mki
echo OPTIMFLAGS=%OPTIMFLAGS%>> getKeplerFromState_Alg_mex.mki
echo DEBUGFLAGS=%DEBUGFLAGS%>> getKeplerFromState_Alg_mex.mki
echo LINKER=%LINKER%>> getKeplerFromState_Alg_mex.mki
echo LINKFLAGS=%LINKFLAGS%>> getKeplerFromState_Alg_mex.mki
echo LINKOPTIMFLAGS=%LINKOPTIMFLAGS%>> getKeplerFromState_Alg_mex.mki
echo LINKDEBUGFLAGS=%LINKDEBUGFLAGS%>> getKeplerFromState_Alg_mex.mki
echo MATLAB_ARCH=%MATLAB_ARCH%>> getKeplerFromState_Alg_mex.mki
echo BORLAND=%BORLAND%>> getKeplerFromState_Alg_mex.mki
echo OMPFLAGS= >> getKeplerFromState_Alg_mex.mki
echo OMPLINKFLAGS= >> getKeplerFromState_Alg_mex.mki
echo EMC_COMPILER=msvcsdk>> getKeplerFromState_Alg_mex.mki
echo EMC_CONFIG=optim>> getKeplerFromState_Alg_mex.mki
"C:\Program Files\MATLAB\R2014b\bin\win64\gmake" -B -f getKeplerFromState_Alg_mex.mk
