@echo off
set MATLAB=C:\PROGRA~1\MATLAB\R2017b
set MATLAB_ARCH=win64
set MATLAB_BIN="C:\Program Files\MATLAB\R2017b\bin"
set ENTRYPOINT=mexFunction
set OUTDIR=.\
set LIB_NAME=getKeplerFromState_Alg_mex
set MEX_NAME=getKeplerFromState_Alg_mex
set MEX_EXT=.mexw64
call setEnv.bat
echo # Make settings for getKeplerFromState_Alg > getKeplerFromState_Alg_mex.mki
echo CC=%COMPILER%>> getKeplerFromState_Alg_mex.mki
echo CXX=%CXXCOMPILER%>> getKeplerFromState_Alg_mex.mki
echo CFLAGS=%COMPFLAGS%>> getKeplerFromState_Alg_mex.mki
echo CXXFLAGS=%CXXCOMPFLAGS%>> getKeplerFromState_Alg_mex.mki
echo OPTIMFLAGS=%OPTIMFLAGS%>> getKeplerFromState_Alg_mex.mki
echo DEBUGFLAGS=%DEBUGFLAGS%>> getKeplerFromState_Alg_mex.mki
echo LINKER=%LINKER%>> getKeplerFromState_Alg_mex.mki
echo LINKFLAGS=%LINKFLAGS%>> getKeplerFromState_Alg_mex.mki
echo LINKOPTIMFLAGS=%LINKOPTIMFLAGS%>> getKeplerFromState_Alg_mex.mki
echo LINKDEBUGFLAGS=%LINKDEBUGFLAGS%>> getKeplerFromState_Alg_mex.mki
echo MATLAB_ARCH=%MATLAB_ARCH%>> getKeplerFromState_Alg_mex.mki
echo OMPFLAGS= >> getKeplerFromState_Alg_mex.mki
echo OMPLINKFLAGS= >> getKeplerFromState_Alg_mex.mki
echo EMC_COMPILER=mingw64>> getKeplerFromState_Alg_mex.mki
echo EMC_CONFIG=optim>> getKeplerFromState_Alg_mex.mki
"C:\Program Files\MATLAB\R2017b\bin\win64\gmake" -B -f getKeplerFromState_Alg_mex.mk
