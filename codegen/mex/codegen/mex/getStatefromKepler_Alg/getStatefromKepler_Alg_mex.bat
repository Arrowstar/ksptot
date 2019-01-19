@echo off
set MATLAB=C:\PROGRA~1\MATLAB\R2017b
set MATLAB_ARCH=win64
set MATLAB_BIN="C:\Program Files\MATLAB\R2017b\bin"
set ENTRYPOINT=mexFunction
set OUTDIR=.\
set LIB_NAME=getStatefromKepler_Alg_mex
set MEX_NAME=getStatefromKepler_Alg_mex
set MEX_EXT=.mexw64
call setEnv.bat
echo # Make settings for getStatefromKepler_Alg > getStatefromKepler_Alg_mex.mki
echo CC=%COMPILER%>> getStatefromKepler_Alg_mex.mki
echo CXX=%CXXCOMPILER%>> getStatefromKepler_Alg_mex.mki
echo CFLAGS=%COMPFLAGS%>> getStatefromKepler_Alg_mex.mki
echo CXXFLAGS=%CXXCOMPFLAGS%>> getStatefromKepler_Alg_mex.mki
echo OPTIMFLAGS=%OPTIMFLAGS%>> getStatefromKepler_Alg_mex.mki
echo DEBUGFLAGS=%DEBUGFLAGS%>> getStatefromKepler_Alg_mex.mki
echo LINKER=%LINKER%>> getStatefromKepler_Alg_mex.mki
echo LINKFLAGS=%LINKFLAGS%>> getStatefromKepler_Alg_mex.mki
echo LINKOPTIMFLAGS=%LINKOPTIMFLAGS%>> getStatefromKepler_Alg_mex.mki
echo LINKDEBUGFLAGS=%LINKDEBUGFLAGS%>> getStatefromKepler_Alg_mex.mki
echo MATLAB_ARCH=%MATLAB_ARCH%>> getStatefromKepler_Alg_mex.mki
echo OMPFLAGS= >> getStatefromKepler_Alg_mex.mki
echo OMPLINKFLAGS= >> getStatefromKepler_Alg_mex.mki
echo EMC_COMPILER=mingw64>> getStatefromKepler_Alg_mex.mki
echo EMC_CONFIG=optim>> getStatefromKepler_Alg_mex.mki
"C:\Program Files\MATLAB\R2017b\bin\win64\gmake" -B -f getStatefromKepler_Alg_mex.mk
