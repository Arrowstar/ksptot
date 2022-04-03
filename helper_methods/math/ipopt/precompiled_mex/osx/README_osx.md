### mexIPOPT
**by Enrico Bertolazzi**

The directory contains the precompiled dynamic libraries for COIN-OR IPOPT library.

The DLL are compiled using coinbrew `https://github.com/coin-or/coinbrew`
and correspond to release 3.14.4.

~~~
./coinbrew fetch Ipopt --no-prompt

./coinbrew build Ipopt --prefix=./IPOPT-build --test --no-prompt --verbosity=3 --with-metis-cflags=-I/usr/local/Cellar/metis/5.1.0/include --with-metis-lflags="-L/usr/local/Cellar/metis/5.1.0/lib -lmetis"

./coinbrew install Ipopt --no-prompt
~~~

copy `libgfortran.5.dylib`, `libquadmath.dylib`


from `/usr/local/Cellar/gcc/11.2.0_3/lib/gcc/11`