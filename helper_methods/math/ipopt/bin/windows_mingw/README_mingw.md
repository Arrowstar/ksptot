### mexIPOPT
**by Enrico Bertolazzi**

The directory contains the precompiled dynamic libraries for COIN-OR IPOPT library
and correspond to release 3.14.4.

Use precompiled binary from:
===========================

https://github.com/JuliaBinaryWrappers/Ipopt_jll.jl


If you want to build binary from scratch:
=========================================

The DLL are compiled using coinbrew `https://github.com/coin-or/coinbrew`

Prerequisite
------------

~~~
pacman -S binutils diffutils git grep make patch pkg-config
pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-gcc-fortran
pacman -S mingw-w64-x86_64-lapack mingw-w64-x86_64-metis
~~~

Build
-----

~~~
./coinbrew fetch Ipopt --no-prompt
./coinbrew build Ipopt --prefix=./IPOPT-build --test --no-prompt --verbosity=3 --skip='ThirdParty/ASL' 
./coinbrew install Ipopt --no-prompt
~~~
