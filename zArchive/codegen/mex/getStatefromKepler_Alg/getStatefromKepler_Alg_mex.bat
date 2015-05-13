@echo off
set MATLAB=C:\PROGRA~1\MATLAB\R2014b
set MATLAB_ARCH=win64
set MATLAB_BIN="C:\Program Files\MATLAB\R2014b\bin"
set ENTRYPOINT=mexFunction
set OUTDIR=.\
set LIB_NAME=getStatefromKepler_Alg_mex
set MEX_NAME=getStatefromKepler_Alg_mex
set MEX_EXT=.mexw64
call setEnv.bat
echo # Make settings for getStatefromKepler_Alg > getStatefromKepler_Alg_mex.mki
echo COMPILER=%COMPILER%>> getStatefromKepler_Alg_mex.mki
echo COMPFLAGS=%COMPFLAGS%>> getStatefromKepler_Alg_mex.mki
echo OPTIMFLAGS=%OPTIMFLAGS%>> getStatefromKepler_Alg_mex.mki
echo DEBUGFLAGS=%DEBUGFLAGS%>> getStatefromKepler_Alg_mex.mki
echo LINKER=%LINKER%>> getStatefromKepler_Alg_mex.mki
echo LINKFLAGS=%LINKFLAGS%>> getStatefromKepler_Alg_mex.mki
echo LINKOPTIMFLAGS=%LINKOPTIMFLAGS%>> getStatefromKepler_Alg_mex.mki
echo LINKDEBUGFLAGS=%LINKDEBUGFLAGS%>> getStatefromKepler_Alg_mex.mki
echo MATLAB_ARCH=%MATLAB_ARCH%>> getStatefromKepler_Alg_mex.mki
echo BORLAND=%BORLAND%>> getStatefromKepler_Alg_mex.mki
echo OMPFLAGS= >> getStatefromKepler_Alg_mex.mki
echo OMPLINKFLAGS= >> getStatefromKepler_Alg_mex.mki
echo EMC_COMPILER=msvcsdk>> getStatefromKepler_Alg_mex.mki
echo EMC_CONFIG=optim>> getStatefromKepler_Alg_mex.mki
"C:\Program Files\MATLAB\R2014b\bin\win64\gmake" -B -f getStatefromKepler_Alg_mex.mk
