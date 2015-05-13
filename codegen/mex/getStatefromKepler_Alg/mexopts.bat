@echo off
rem LCCOPTS.BAT
rem
rem    Compile and link options used for building MEX-files
rem    using the LCC compiler version 2.4 
rem
rem StorageVersion: 1.0
rem CkeyFileName: LCCOPTS.BAT
rem CkeyName: Lcc-win32
rem CkeyManufacturer: LCC
rem CkeyVersion: 2.4
rem CkeyLanguage: C
rem CkeyLinkerName: LCC
rem CkeyLinkerVersion: 2.4
rem
rem    $Revision: 1.14.4.9 $  $Date: 2012/07/23 18:50:25 $
rem
rem ********************************************************************
rem General parameters
rem ********************************************************************

set MATLAB=%MATLAB%
set LCCINSTALLDIR=C:\PROGRA~2\MATLAB\R2013a\sys\lcc
set PATH=%LCCINSTALLDIR%\bin;%PATH%

rem ********************************************************************
rem Compiler parameters
rem ********************************************************************
set COMPILER=lcc
set COMPFLAGS=-c -I"%MATLAB%\sys\lcc\include" -DMATLAB_MEX_FILE -noregistrylookup
set OPTIMFLAGS=-DNDEBUG
set DEBUGFLAGS=-g4
set NAME_OBJECT=-Fo
set MW_TARGET_ARCH=win32

rem ********************************************************************
rem Library creation command
rem ********************************************************************
set PRELINK_CMDS1=lcc %COMPFLAGS% "%MATLAB%\sys\lcc\mex\lccstub.c" -Fo"%LIB_NAME%2.obj"

rem ********************************************************************
rem Linker parameters
rem ********************************************************************
set LIBLOC=%MATLAB%\extern\lib\win32\lcc
set LINKER=lcclnk
set LINKFLAGS= -tmpdir "%OUTDIR%." -dll "%MATLAB%\extern\lib\win32\lcc\%ENTRYPOINT%.def" -L"%MATLAB%\sys\lcc\lib" -libpath "%LIBLOC%" "%LIB_NAME%2.obj"
set LINKFLAGSPOST=libmx.lib libmex.lib libmat.lib
set LINKOPTIMFLAGS=-s
set LINKDEBUGFLAGS=
set LINK_FILE=
set LINK_LIB=
set NAME_OUTPUT=-o "%OUTDIR%%MEX_NAME%%MEX_EXT%"
set RSP_FILE_INDICATOR=@

rem ********************************************************************
rem Resource compiler parameters
rem ********************************************************************
set RC_COMPILER=lrc -I"%MATLAB%\sys\lcc\include" -noregistrylookup -fo"%OUTDIR%mexversion.res"
set RC_LINKER=

set POSTLINK_CMDS1=del "%LIB_NAME%2.obj"
set POSTLINK_CMDS2=del "%OUTDIR%%MEX_NAME%.exp"
set POSTLINK_CMDS3=del "%OUTDIR%%MEX_NAME%.lib"
