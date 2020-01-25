%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  file: Compile.m                                                         %
%                                                                          %
%  IPOPT MATLAB-interface provided by:                                     %
%      Enrico Bertolazzi (enrico.bertolazzi@unitn.it)                      %
%      Dipartimento di Ingegneria Industriale                              %
%      Universita` degli Studi di Trento                                   %
%      Via Sommarive 9, I-38123, Trento, Italy                             %
%                                                                          %
%  This IPOPT MATLAB-interface is derived from the code by:                %
%        Peter Carbonetto                                                  %
%        Dept. of Computer Science                                         %
%        University of British Columbia, May 19, 2007                      %
%        Original code is published under the Eclipse Public License.      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

files = [ '../src/ipopt.cc ', '../src/IpoptInterfaceCommon.cc' ] ;

%COMPFLAGS  = [ '-O2 -std=c++11 -shared-libgcc -shared-libstdc++ ' ] ;
CXXFLAGS = [ '-O2 -static-libgfortran -lgfortran -lmwma57 ' ] ;
DEFINE   = [ '-DNDEBUG -DMATLAB_MEXFILE' ] ;%  -static-libgcc -static-libstdc++ -lstdc++ -lgfortran  -DHAVE_CSTDDEF ' ] ;% -DHAVE_CONFIG_H -lmwlapack -lmwblas

IPOPTBASE = [ '..\binary' ];
DIRLIB    = [ IPOPTBASE '\lib' ];
DLLLIB    = [ IPOPTBASE '\dll' ];
HDR       = [ IPOPTBASE '\include\coin' ];
INCL      = [' -I..\src -I' HDR  ];

%ROOT      = [ matlabroot, '\extern\lib\win64\mingw64' ];

LIBS       = [ DIRLIB, '\libipopt.a ', ...
               DIRLIB, '\libipopt.dll.a ', ...
               DIRLIB, '\libcoinmumps.dll.a ', ...
               DIRLIB, '\libcoinmetis.dll.a ', ...
               DIRLIB, '\libCoinUtils.dll.a ', ...
               DIRLIB, '\libcoinlapack.dll.a ', ...
               DIRLIB, '\libcoinblas.dll.a '];

MEXFLAGS = [ '-v -largeArrayDims -outdir ', DLLLIB, ' CXXFLAGS="$CXXFLAGS ' CXXFLAGS '" ' ] ;
cmd = sprintf('mex %s %s %s %s %s ',MEXFLAGS,DEFINE,INCL,files,LIBS) ;
disp(cmd);
eval(cmd);
addpath(DLLLIB);
%