component 'runtime' do |pkg, _settings, platform|
  if platform.is_cross_compiled_linux? || platform.name =~ /solaris-11/
    if platform.is_solaris? && !platform.is_cross_compiled? && platform.architecture == 'sparc'
      pkg.build_requires 'pl-gcc10'
      # using binutils in /usr/ccs/bin
    else
      pkg.build_requires "pl-gcc-#{platform.architecture}"
      pkg.build_requires "pl-binutils-#{platform.architecture}"
    end
  elsif platform.name == 'sles-11-x86_64'
    pkg.build_requires 'pl-gcc8'
  elsif platform.name =~ /el-6|redhatfips-7|sles-12/
    pkg.build_requires 'pl-gcc'
  end
end
