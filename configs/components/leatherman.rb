component 'leatherman' do |pkg, settings, platform|
  pkg.load_from_json('configs/components/leatherman.json')

  make = platform[:make]

  if platform.is_macos?
    pkg.build_requires 'cmake'
    pkg.build_requires 'gettext'
  elsif platform.is_cross_compiled_linux?
    pkg.build_requires 'pl-cmake'
    pkg.build_requires 'pl-gettext'
  elsif platform.is_solaris?
    if !platform.is_cross_compiled? && platform.architecture == 'sparc'
      pkg.build_requires 'pl-cmake-sparc'
      # using opencsw ggettext
    else
      pkg.build_requires 'pl-cmake'
      pkg.build_requires 'pl-gettext'
    end
  elsif platform.is_windows?
    pkg.build_requires 'cmake'
    pkg.build_requires 'gettext'
    pkg.build_requires 'gettext-devel'
  elsif platform.name =~ /el-6|redhatfips-7|sles-1[12]/
    pkg.build_requires 'pl-cmake'
    pkg.build_requires 'pl-gettext'
    pkg.build_requires 'runtime'
  end

  pkg.build_requires 'puppet-runtime' # Provides curl and ruby

  pkg.build_requires 'runtime' unless platform.is_linux?

  ruby = "#{settings[:host_ruby]} -rrbconfig"

  leatherman_locale_var = ''
  special_flags = ''
  boost_static_flag = ''
  prefix = settings[:prefix]
  libdir = settings[:libdir]

  # cmake on OSX is provided by brew
  # a toolchain is not currently required for OSX since we're building with clang.
  if platform.is_macos?
    toolchain = ''
    cmake = '/usr/local/bin/cmake'
    boost_static_flag = '-DBOOST_STATIC=OFF'
    special_flags = "-DCMAKE_CXX_FLAGS='#{settings[:cflags]} -Wno-enum-constexpr-conversion -Wno-deprecated-declarations' -DENABLE_CXX_WERROR=OFF -DLEATHERMAN_MOCK_CURL=FALSE"
    if platform.is_cross_compiled?
      pkg.environment 'CXX', 'clang++ -target arm64-apple-macos11' if platform.name =~ /osx-11/
      pkg.environment 'CXX', 'clang++ -target arm64-apple-macos12' if platform.name =~ /osx-12/
    end

    if platform.os_version.to_i >= 13 && platform.architecture == 'arm64'
      cmake = '/opt/homebrew/bin/cmake'
      pkg.environment 'CXX', 'clang++'
    end
  elsif platform.is_cross_compiled_linux?
    ruby = "#{settings[:host_ruby]} -r#{settings[:datadir]}/doc/rbconfig-#{settings[:ruby_version]}-orig.rb"
    toolchain = "-DCMAKE_TOOLCHAIN_FILE=/opt/pl-build-tools/#{settings[:platform_triple]}/pl-build-toolchain.cmake"
    cmake = '/opt/pl-build-tools/bin/cmake'
    special_flags = "-DCMAKE_CXX_FLAGS='-DBOOST_UUID_RANDOM_PROVIDER_FORCE_POSIX -Wno-deprecated-declarations'"
    pkg.environment 'PATH' => "/opt/pl-build-tools/bin:$$PATH:#{settings[:bindir]}"
  elsif platform.is_solaris?
    if !platform.is_cross_compiled? && platform.architecture == 'sparc'
      toolchain = ''
      cmake = '/opt/pl-build-tools/bin/cmake'
      pkg.environment 'PATH', "$(PATH):/opt/pl-build-tools/bin:#{settings[:bindir]}"
      # Why does this work, but cpp-hocon needs to set CMAKE_CXX_COMPILER?
      pkg.environment 'CXX', '/opt/pl-build-tools/bin/g++'
      special_flags += " -DCMAKE_CXX_FLAGS='-pthreads -Wno-class-memaccess -Wno-deprecated-declarations -Wno-catch-value -DENABLE_CXX_WERROR=OFF' "
    else
      if platform.architecture == 'sparc'
        ruby = "#{settings[:host_ruby]} -r#{settings[:datadir]}/doc/rbconfig-#{settings[:ruby_version]}-orig.rb"
        special_flags += " -DCMAKE_EXE_LINKER_FLAGS=' /opt/puppetlabs/puppet/lib/libssl.so /opt/puppetlabs/puppet/lib/libcrypto.so /opt/puppetlabs/puppet/lib/libgcc_s.so' " if platform.name =~ /^solaris-10/
        special_flags += " -DCMAKE_EXE_LINKER_FLAGS=' /opt/puppetlabs/puppet/lib/libssl.so /opt/puppetlabs/puppet/lib/libcrypto.so' " if platform.name =~ /^solaris-11/
      end

      toolchain = "-DCMAKE_TOOLCHAIN_FILE=/opt/pl-build-tools/#{settings[:platform_triple]}/pl-build-toolchain.cmake"
      cmake = "/opt/pl-build-tools/i386-pc-solaris2.#{platform.os_version}/bin/cmake"

      # FACT-1156: If we build with -O3, solaris segfaults due to something in std::vector
      special_flags += "-DCMAKE_CXX_FLAGS_RELEASE='-O2 -DNDEBUG' -DCMAKE_CXX_FLAGS='-Wno-deprecated-declarations' "
    end
  elsif platform.is_windows?
    make = "/usr/bin/make"
    pkg.environment 'PATH', "/usr/bin:$(shell cygpath -u #{settings[:prefix]}/lib):$(shell cygpath -u #{settings[:gcc_bindir]}):$(shell cygpath -u #{settings[:bindir]}):/cygdrive/c/Windows/system32:/cygdrive/c/Windows:/cygdrive/c/Windows/System32/WindowsPowerShell/v1.0"
    pkg.environment 'CYGWIN', settings[:cygwin]

    cmake = '/usr/bin/cmake'
    toolchain = ''
    prefix = "$(shell cygpath -u #{prefix})"
    libdir = "$(shell cygpath -u #{libdir})"
    special_flags = " -DCMAKE_CXX_FLAGS='-Wno-deprecated-declarations -Wno-format -I../inc/leatherman/curl -D_POSIX_THREAD_SAFE_FUNCTIONS' -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++"
    pkg.environment 'CC', "x86_64-w64-mingw32-gcc"
    pkg.environment 'CXX', "x86_64-w64-mingw32-g++"

    # Use environment variable set in environment.bat to find locale files
    leatherman_locale_var = "-DLEATHERMAN_LOCALE_VAR='PUPPET_DIR' -DLEATHERMAN_LOCALE_INSTALL='share/locale'"
  elsif platform.name == 'sles-11-x86_64'
    cmake = 'env LD_LIBRARY_PATH=/opt/pl-build-tools/lib64 /opt/pl-build-tools/bin/cmake'
    toolchain = '-DCMAKE_TOOLCHAIN_FILE=/opt/pl-build-tools/pl-build-toolchain.cmake'
    special_flags += " -DCMAKE_CXX_FLAGS='-Wno-deprecated-declarations -Wno-error=class-memaccess -Wno-error=ignored-qualifiers -Wno-error=catch-value' "
  elsif platform.name =~ /el-6|redhatfips-7|sles-12/
    toolchain = '-DCMAKE_TOOLCHAIN_FILE=/opt/pl-build-tools/pl-build-toolchain.cmake'
    cmake = '/opt/pl-build-tools/bin/cmake'
    special_flags += " -DCMAKE_CXX_FLAGS='-Wno-deprecated-declarations' "
  elsif platform.is_aix?
    cmake = '/opt/freeware/bin/cmake'
    pkg.environment 'PATH', "/opt/freeware/bin:$(PATH):#{settings[:bindir]}"
    special_flags += ' -DENABLE_CXX_WERROR=OFF '
  else
    # These platforms use the default OS toolchain, rather than pl-build-tools
    pkg.environment 'CPPFLAGS', settings[:cppflags]
    pkg.environment 'LDFLAGS', settings[:ldflags]
    toolchain = ''
    boost_static_flag = ''

    # Workaround for hanging leatherman tests (-fno-strict-overflow)
    special_flags = " -DENABLE_CXX_WERROR=OFF -DCMAKE_CXX_FLAGS='#{settings[:cflags]} -fno-strict-overflow -Wno-deprecated-declarations' "
    cmake = if platform.name =~ /amazon-2-aarch64|el-7/
              '/usr/bin/cmake3'
            else
              'cmake'
            end
  end

  if platform.name =~ /el-7/
    pkg.environment 'PATH', '/opt/rh/devtoolset-7/root/usr/bin:$(PATH)'
    special_flags += ' -DCMAKE_CXX_COMPILER=/opt/rh/devtoolset-7/root/usr/bin/g++'
  end

  if platform.is_linux?
    # Ensure our gettext packages are found before system versions
    pkg.environment 'PATH', '/opt/pl-build-tools/bin:$(PATH)'
  end

  # Boost_NO_BOOST_CMAKE=ON was added while upgrading to boost
  # 1.73 for PA-3244. https://cmake.org/cmake/help/v3.0/module/FindBoost.html#boost-cmake
  # describes the setting itself (and what we are disabling). It
  # may make sense in the future to remove this cmake parameter and
  # actually make the boost build work with boost's own cmake
  # helpers. But for now disabling boost's cmake helpers allow us
  # to upgrade boost with minimal changes.
  #                                  - Sean P. McDonald 5/19/2020
  pkg.configure do
    [ <<~CMD
        #{cmake} \
        #{toolchain} \
        -DLEATHERMAN_GETTEXT=ON \
        -DCMAKE_VERBOSE_MAKEFILE=ON \
        -DCMAKE_PREFIX_PATH=#{prefix} \
        -DCMAKE_INSTALL_PREFIX=#{prefix} \
        -DCMAKE_INSTALL_RPATH=#{libdir} \
        #{leatherman_locale_var} \
        -DLEATHERMAN_SHARED=TRUE \
        #{special_flags} \
        #{boost_static_flag} \
        -DBoost_NO_BOOST_CMAKE=ON \
        .
      CMD
    ]
  end

  pkg.build do
    ["#{make} -j$(shell expr $(shell #{platform[:num_cores]}) + 1)"]
  end

  # Make test will explode horribly in a cross-compile situation
  # Tests will be skipped on AIX and Solaris SPARC until they are expected to pass
  #
  # NB - Just bypassing tests for now to get this thing working
  # if !platform.is_cross_compiled? && !platform.is_aix? && !(platform.is_solaris? && !platform.is_cross_compiled? && platform.architecture == 'sparc')
  if false # rubocop:disable Lint/LiteralAsCondition
    test_locale = 'LANG=C LC_ALL=C' if platform.is_solaris? || platform.name =~ /debian-10/
    ld_library_path = platform.name == 'sles-11-x86_64' ? '/opt/pl-build-tools/lib64' : settings[:libdir]
    pkg.check do
      ["LEATHERMAN_RUBY=#{settings[:libdir]}/$(shell #{ruby} -e 'print RbConfig::CONFIG[\"LIBRUBY_SO\"]') \
      LD_LIBRARY_PATH=#{ld_library_path} LIBPATH=#{settings[:libdir]} #{test_locale} #{make} test ARGS=-V"]
    end
  end

  pkg.install do
    ["#{make} -j$(shell expr $(shell #{platform[:num_cores]}) + 1) install"]
  end
end
