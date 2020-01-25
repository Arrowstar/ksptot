%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  file: compile_linux.m                                                   %
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

% full path MATLAB
MATLAB = '/usr/local/MATLAB' ;

% interface sources
files = [ '../src/ipopt.cc ', ...
          '../src/IpoptInterfaceCommon.cc' ] ;

% compiler options
CXXFLAGS = '-fPIC -O3 -DMATLAB_MEXFILE -DHAVE_CSTDDEF ' ;

% on some linux system STL do not contain copy_n
% comment the next line if your system know copy_n
CXXFLAGS = [CXXFLAGS '-DIPOPT_INTERFACE_MISSING_COPY_N '] ;

% where are headers files and ipopt libraries
PREFIX = '/opt/local2' ;

INCL = [ '-I../src ' ...
         '-I' PREFIX '/include ' ...
         '-I' PREFIX '/include/coin ' ] ;

% libraries linked dynamically
% -lgfortran -lquadmath -lstdc++ -lblas -llapack  should be installed statically
% But on some linux this cannot be done cause the library is not 
% compiled with the switch `-fno-common`
% 
LIBS = [ '-L' PREFIX '/lib -L/usr/lib -lgfortran -lquadmath -lstdc++ -ldl -lm -lc' ] ; 

% If you implementation of IPOPT do not use ma57 comment the next line.
LIBS = [ LIBS ' -L' MATLAB '/bin/glnxa64 -lmwma57' ] ;
% library MA57 inside MATLAB

% libraries linked statically (check for atlas)
LIBS2 = '-Wl,-Bstatic -L/opt/local2/lib -lipopt -lcoinmumps -lcoinlapack -lcoinblas -Wl,-Bdynamic ';

% compiler options
MEXFLAGS = [ '-v -cxx -largeArrayDims ' ...
             'COPTIMFLAGS="' CXXFLAGS '" ' ...
             'CXXOPTIMFLAGS="' CXXFLAGS '" ' ...
             'LDOPTIMFLAGS="" ' ...
             'CXXLIBS=''$CXXLIBS ' LIBS2 ''''  ] ; % -static -shared-libgcc 

% build and execute compilation command
cmd = sprintf('mex %s %s %s %s',INCL,files,MEXFLAGS,LIBS) ;
eval(cmd);
