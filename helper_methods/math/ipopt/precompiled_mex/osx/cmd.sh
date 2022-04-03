
install_name_tool -id "@loader_path/libipopt.3.dylib" libipopt.3.dylib
install_name_tool -change /usr/local/gfortran/lib/libgfortran.5.dylib @loader_path/libgfortran.5.dylib libipopt.3.dylib
install_name_tool -change /usr/local/gfortran/lib/libquadmath.0.dylib @loader_path/libquadmath.0.dylib libipopt.3.dylib
install_name_tool -change /usr/local/gfortran/lib/libgcc_s.1.dylib @loader_path/libgcc_s.1.dylib libipopt.3.dylib
install_name_tool -change /usr/lib/libc++.1.dylib @loader_path/libc++.1.dylib libipopt.3.dylib

install_name_tool -id "@loader_path/libcoinmumps.2.dylib" libcoinmumps.2.dylib
install_name_tool -change /usr/local/gfortran/lib/libgfortran.5.dylib @loader_path/libgfortran.5.dylib libcoinmumps.2.dylib
install_name_tool -change /usr/local/gfortran/lib/libquadmath.0.dylib @loader_path/libquadmath.0.dylib libcoinmumps.2.dylib
install_name_tool -change /usr/local/gfortran/lib/libgcc_s.1.dylib @loader_path/libgcc_s.1.dylib libcoinmumps.2.dylib

install_name_tool -id "@loader_path/libquadmath.0.dylib" libquadmath.0.dylib
install_name_tool -change /usr/local/gfortran/lib/libgcc_s.1.dylib @loader_path/libgcc_s.1.dylib libquadmath.0.dylib

install_name_tool -id "@loader_path/libgfortran.5.dylib" libgfortran.5.dylib
install_name_tool -change /usr/local/gfortran/lib/libquadmath.0.dylib @loader_path/libquadmath.0.dylib libgfortran.5.dylib
install_name_tool -change /usr/local/gfortran/lib/libgcc_s.1.dylib @loader_path/libgcc_s.1.dylib libgfortran.5.dylib

install_name_tool -id "@loader_path/libc++.1.dylib" libc++.1.dylib
install_name_tool -change /usr/lib/libc++abi.dylib @loader_path/libc++abi.dylib libc++.1.dylib
install_name_tool -id "@loader_path/libc++abi.dylib" libc++abi.dylib
