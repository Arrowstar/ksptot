require 'colorize'
#
# Adjust path for depend on dylib in the local bin directory
#
LIST = %w(
libasl.3
libmp
libblas
libdmumps
libgomp.1
libgcc_s.1
libgcc_s.1.1
libgfortran.5
libipopt.3
libipoptamplinterface.3
liblapack
libmpiseq
libmumps_common
libopenblas.0
libpord
libquadmath.0
libsipopt.3
libstdc++.6
)
LIST.each do |lib|
  system('install_name_tool -id "@loader_path/'+lib+'.dylib" '+lib+'.dylib');
  LIST.each do |name|
    path = `otool -L #{lib}.dylib | grep #{name}`;
    if path != "" then
      path.gsub!(/\s*([^\s]+).*/,'\1')
      path.gsub!(/\n/,'')
      cmd = 'install_name_tool -change '+path+' @loader_path/'+name+'.dylib ' + lib + '.dylib'
      puts cmd.yellow
      system(cmd);
    end
  end
end
