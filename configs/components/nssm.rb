component 'nssm' do |pkg, settings, platform|
  #pkg.load_from_json('configs/components/nssm.json')

  # Rather than build this ourselves every time, we use a precompiled binary, since this
  # binary hasn't changed in the last 5 years. Leaving the code here in case we need to
  # make changes and recompile it.

  #build_arch = platform.architecture == 'x64' ? 'x64' : 'Win32'
  #platform_toolset = 'v141'
  #target_platform_version = '8.1'

  #pkg.install do
  #  [
  #    "#{settings[:msbuild]} nssm.vcxproj /detailedsummary /p:Configuration=Release /p:OutDir=.\\\\out\\\\ /p:Platform=#{build_arch} /p:PlatformToolset=#{platform_toolset} /p:TargetPlatformVersion=#{target_platform_version}"
  #  ]
  #end

  #pkg.install_file 'out/nssm.exe', "#{settings[:bindir]}/nssm-pxp-agent.exe"
  pkg.md5sum '06056fd7f5226410c564ce19b87020c8'
  pkg.url 'https://artifacts.overlookinfratech.com/components/nssm-pxp-agent.exe'
  pkg.install_file 'nssm-pxp-agent.exe', "#{settings[:bindir]}/nssm-pxp-agent.exe"
end
