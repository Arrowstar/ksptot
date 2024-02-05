require 'colorize'
#
# Adjust path for depend on dylib in the local bin directory
#
require 'fileutils'

hbrew = `brew --prefix`.chop;
#puts "hbrew = #{hbrew}"

fortran_home = Dir["#{hbrew}/Cellar/gcc/*/lib/gcc/current"].last
ipopt_hdr    = Dir["#{hbrew}/Cellar/ipopt/*/include"].last
ipopt_lib    = Dir["#{hbrew}/Cellar/ipopt/*/lib"].last
openblas_lib = Dir["#{hbrew}/Cellar/openblas/*/lib"].last
ampl         = Dir["#{hbrew}/Cellar/ampl-mp/*/lib"].last

puts "fortran_home = #{fortran_home}"
puts "ipopt_hdr    = #{ipopt_hdr}"
puts "ipopt_lib    = #{ipopt_lib}"
puts "openblas_lib = #{openblas_lib}"

FileUtils.rm_rf "../../src_ipopt_osx"
FileUtils.mkdir_p "../../src_ipopt_osx"
FileUtils.cp_r "#{ipopt_hdr}/coin-or", "../../src_ipopt_osx"

[
  'libgfortran.5.dylib',
  'libquadmath.0.dylib',
  'libstdc++.6.dylib',
  'libgomp.1.dylib',
  'libgcc_s.1.dylib',
  'libgcc_s.1.1.dylib'
].each do |lib|
  #puts fortran_home+"/"+lib, lib
  FileUtils.rm lib if File.exist? lib
  FileUtils.cp "#{fortran_home}/#{lib}", lib
end

[
  'libopenblas.0.dylib',
  'libblas.dylib',
  'liblapack.dylib'
].each do |lib|
  #puts fortran_home+"/"+lib, lib
  FileUtils.rm lib if File.exist? lib
  FileUtils.cp "#{openblas_lib}/#{lib}", lib
end

[
  'libasl.3.dylib',
  'libmp.dylib'
].each do |lib|
  #puts fortran_home+"/"+lib, lib
  FileUtils.rm lib if File.exist? lib
  FileUtils.cp "#{ampl}/#{lib}", lib
end

[
  'libdmumps.dylib',
  'libipopt.3.dylib',
  'libipoptamplinterface.3.dylib',
  'libmpiseq.dylib',
  'libmumps_common.dylib',
  'libpord.dylib',
  'libsipopt.3.dylib'
].each do |lib|
  FileUtils.rm lib if File.exist? lib
  FileUtils.cp "#{ipopt_lib}/#{lib}", lib
end
