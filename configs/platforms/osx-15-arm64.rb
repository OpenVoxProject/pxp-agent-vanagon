platform 'osx-15-arm64' do |plat|
  plat.inherit_from_default
  plat.make 'sudo /usr/bin/make'
end
