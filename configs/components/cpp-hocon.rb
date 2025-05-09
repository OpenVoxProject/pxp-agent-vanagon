component 'cpp-hocon' do |pkg, settings, platform|
  pkg.load_from_json('configs/components/cpp-hocon.json')

  pkg.build_requires('leatherman')

  make = platform[:make]
  boost_static_flag = ''

  # cmake on OSX is provided by brew
  # a toolchain is not currently required for OSX since we're building with clang.
  if platform.is_macos?
    toolchain = ''
    cmake = '/usr/local/bin/cmake'
    boost_static_flag = '-DBOOST_STATIC=OFF'
    special_flags = "-DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_CXX_FLAGS='#{settings[:cflags]}' -DENABLE_CXX_WERROR=OFF"
    if platform.is_cross_compiled?
      pkg.environment 'CXX', 'clang++ -target arm64-apple-macos11' if platform.name =~ /osx-11/
      pkg.environment 'CXX', 'clang++ -target arm64-apple-macos12' if platform.name =~ /osx-12/
    end

    if platform.architecture == 'arm64' && platform.os_version.to_i >= 13
      pkg.environment 'CXX', 'clang++'
      cmake = '/opt/homebrew/bin/cmake'
    end
  elsif platform.is_cross_compiled_linux?
    toolchain = "-DCMAKE_TOOLCHAIN_FILE=/opt/pl-build-tools/#{settings[:platform_triple]}/pl-build-toolchain.cmake"
    cmake = '/opt/pl-build-tools/bin/cmake'
  elsif platform.is_solaris?
    if !platform.is_cross_compiled? && platform.architecture == 'sparc'
      toolchain = ''
      cmake = '/opt/pl-build-tools/bin/cmake'
      pkg.environment 'PATH', '$(PATH):/opt/pl-build-tools/bin'
      special_flags = " -DCMAKE_CXX_COMPILER=/opt/pl-build-tools/bin/g++ -DCMAKE_CXX_FLAGS='-pthreads' -DENABLE_CXX_WERROR=OFF "
    else
      toolchain = "-DCMAKE_TOOLCHAIN_FILE=/opt/pl-build-tools/#{settings[:platform_triple]}/pl-build-toolchain.cmake"
      cmake = "/opt/pl-build-tools/i386-pc-solaris2.#{platform.os_version}/bin/cmake"

      # FACT-1156: If we build with -O3, solaris segfaults due to something in std::vector
      special_flags = "-DCMAKE_CXX_FLAGS_RELEASE='-O2 -DNDEBUG'"
    end
  elsif platform.is_windows?
    make = "#{settings[:gcc_bindir]}/mingw32-make"
    pkg.environment 'PATH', "$(shell cygpath -u #{settings[:prefix]}/lib):$(shell cygpath -u #{settings[:gcc_bindir]}):$(shell cygpath -u #{settings[:bindir]}):/cygdrive/c/Windows/system32:/cygdrive/c/Windows:/cygdrive/c/Windows/System32/WindowsPowerShell/v1.0"
    pkg.environment 'CYGWIN', settings[:cygwin]

    cmake = 'C:/ProgramData/chocolatey/bin/cmake.exe -G "MinGW Makefiles"'
    toolchain = "-DCMAKE_TOOLCHAIN_FILE=#{settings[:tools_root]}/pl-build-toolchain.cmake"
  elsif platform.name =~ /el-6|redhatfips-7|sles-1[12]/
    toolchain = '-DCMAKE_TOOLCHAIN_FILE=/opt/pl-build-tools/pl-build-toolchain.cmake'
    cmake = '/opt/pl-build-tools/bin/cmake'
  elsif platform.is_aix?
    pkg.environment 'PATH', '/opt/freeware/bin:$(PATH)'
    cmake = '/opt/freeware/bin/cmake'
    special_flags = '-DENABLE_CXX_WERROR=OFF'
  else
    # These platforms use the default OS toolchain, rather than pl-build-tools
    pkg.environment 'CPPFLAGS', settings[:cppflags]
    pkg.environment 'LDFLAGS', settings[:ldflags]
    toolchain = ''
    boost_static_flag = '-DBOOST_STATIC=OFF'
    special_flags = " -DENABLE_CXX_WERROR=OFF -DCMAKE_CXX_FLAGS='#{settings[:cflags]}'"
    cmake = if platform.name =~ /amazon-2|el-7/
              '/usr/bin/cmake3'
            else
              'cmake'
            end
  end

  cmake_cxx_compiler = ''
  if platform.name =~ /el-7/
    pkg.environment 'PATH', '/opt/rh/devtoolset-7/root/usr/bin:$(PATH)'
    cmake_cxx_compiler = '-DCMAKE_CXX_COMPILER=/opt/rh/devtoolset-7/root/usr/bin/g++'
  end

  # Until we build our own gettext packages, disable using locales.
  # gettext 0.17 is required to compile .mo files with msgctxt.
  #
  # Boost_NO_BOOST_CMAKE=ON was added while upgrading to boost
  # 1.73 for PA-3244. https://cmake.org/cmake/help/v3.0/module/FindBoost.html#boost-cmake
  # describes the setting itself (and what we are disabling). It
  # may make sense in the future to remove this cmake parameter and
  # actually make the boost build work with boost's own cmake
  # helpers. But for now disabling boost's cmake helpers allow us
  # to upgrade boost with minimal changes.
  #                                  - Sean P. McDonald 5/19/2020
  pkg.configure do
    ["#{cmake} \
        #{toolchain} \
        -DCMAKE_VERBOSE_MAKEFILE=ON \
        -DCMAKE_PREFIX_PATH=#{settings[:prefix]} \
        -DCMAKE_INSTALL_PREFIX=#{settings[:prefix]} \
        #{special_flags} \
        #{boost_static_flag} \
        -DBoost_NO_BOOST_CMAKE=ON \
        #{cmake_cxx_compiler} \
        ."]
  end

  # Make test will explode horribly in a cross-compile situation
  # Tests will be skipped on AIX until they are expected to pass
  test = if platform.is_cross_compiled? || platform.is_aix?
           if platform.is_macos?
             '/usr/bin/true'
           else
             '/bin/true'
           end
         else
           "#{make} test ARGS=-V"
         end

  test = "LANG=C LC_ALL=C #{test}" if platform.is_solaris? && !platform.is_cross_compiled?

  pkg.build do
    # Until a `check` target exists, run tests are part of the build.
    [
      "#{make} -j$(shell expr $(shell #{platform[:num_cores]}) + 1)",
      test.to_s
    ]
  end

  pkg.install do
    ["#{make} -j$(shell expr $(shell #{platform[:num_cores]}) + 1) install"]
  end
end
