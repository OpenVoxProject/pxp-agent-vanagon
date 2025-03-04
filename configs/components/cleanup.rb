# This component exists only to remove all the files that are not needed in the final package.
component 'cleanup' do |pkg, settings, _platform|
  # This component must depend on all other C++ components in order to be
  # executed last, after they all finish building.
  pkg.build_requires 'puppet-runtime'
  pkg.build_requires 'cpp-pcp-client'
  pkg.build_requires 'cpp-hocon'
  pkg.build_requires 'leatherman'
  pkg.build_requires 'pxp-agent'

  rm = platform.is_windows? ? '/usr/bin/rm' : 'rm'
  cleanup_steps = []

  cleanup_steps << "#{rm} -rf #{settings[:includedir]}"
  cleanup_steps << "#{rm} -rf #{settings[:prefix]}/share"
  cleanup_steps << "#{rm} -rf #{settings[:prefix]}/ssl"
  cleanup_steps << "#{rm} -rf #{settings[:prefix]}/usr/local"
  cleanup_steps << "#{rm} -rf #{settings[:prefix]}/CMake"
  cleanup_steps << "#{rm} -rf #{settings[:libdir]}/*.{la,a}"

  if platform.is_windows?
    %w[
      erb gem httpclient irb libcrypto libcurl thor
      liggcc libconv libssl rake x64-msvcrt-ruby rdoc ri rubyw
      curl c_rehash libconv openssl libgcc_s_sjlj yaml-cpp
      msvcrt-ruby libmsvcrt-ruby libeay32 ssleay32 ruby
    ].each do |component|
      cleanup_steps << "#{rm} -rf #{settings[:bindir]}/#{component}*"
    end

    %w[
      cmake engines pkgconfig ruby libx64-msvcrt yaml-cpp libssl
      libcrypto libcurl libssl libx64-msvcrt yaml-cpp
    ].each do |component|
      cleanup_steps << "#{rm} -rf #{settings[:libdir]}/#{component}*"
    end
  else
    bins = "-name '*pxp-agent*' -o -name '*execution_wrapper*' -o -name '*apply_ruby_shim.rb*'"
    cleanup_steps << "#{platform.find} #{settings[:bindir]} -type f ! \\( #{bins} \\) -exec #{rm} -rf {} +"
    cleanup_steps << "#{platform.find}  #{settings[:libdir]} -type d ! -name 'lib' -exec #{rm} -rf {} +"
    libs = "-name '*leatherman*' -o -name '*libpxp*' -o -name '*libcpp*'"
    libs += " -o -name '*libstdc*' -o -name '*libgcc_s*'" if platform.is_aix?
    cleanup_steps << "#{platform.find}  #{settings[:libdir]} ! -name 'lib' ! \\( #{libs} \\) -exec #{rm} -rf {} +"
  end

  pkg.install { cleanup_steps }
end
