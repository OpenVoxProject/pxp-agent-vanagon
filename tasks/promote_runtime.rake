require 'open3'

namespace :vox do
  desc 'Promote a puppet-runtime tag into this repo'
  task :promote_runtime, [:tag] do |_, args|
    abort 'You must provide a tag for puppet-runtime that has been uploaded to s3.osuosl.org.' if args[:tag].nil? || args[:tag].empty?

    branch = run_command('git rev-parse --abbrev-ref HEAD')

    munged = args[:tag].gsub('-', '.')
    data = <<~DATA
      {"location":"https://s3.osuosl.org/puppet-artifacts/puppet-runtime/#{args[:tag]}/","version":"#{munged}"}
    DATA
    File.write('configs/components/puppet-runtime.json', data)

    puts 'Writing puppet-runtime.json'
    run_command('git add configs/components/puppet-runtime.json')
    puts 'Creating commit'
    run_command("git commit -m 'Promote puppet-runtime #{args[:tag]}'")
    puts 'Pushing to origin'
    run_command("git push origin #{branch}")
  end
end
