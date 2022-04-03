require 'colorize'
#
# Adjust path for depend on dylib in the local bin directory
#
['libgfortran.5','libquadmath.0','libstdc++.6','libgcc_s.1','libipopt.3','libcoinmumps.3','libmetis'].each do |lib|
  system('install_name_tool -id "@loader_path/'+lib+'.dylib" '+lib+'.dylib');
  ['libgfortran.5','libquadmath.0','libcoinmumps.3','libstdc++.6','libgcc_s.1'].each do |name|
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