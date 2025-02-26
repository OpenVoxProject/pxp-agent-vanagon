require 'open3'

namespace :vox do
  desc 'Build vanagon project with Docker'
  task :build, [:project, :platform] do |_, args|
    # This is not currently really any different than 'bundle exec build pxp-agent <platform> --engine docker',
    # but adding this machinery so we can make it fancier later and have a common way to build
    # locally and in an action.
    args.with_defaults(project: 'pxp-agent')
    project = args[:project]

    abort 'You must provide a platform.' if args[:platform].nil? || args[:platform].empty?
    platform = args[:platform]

    if platform =~ /^osx-/
      abort 'It appears homebrew is not installed. Install it first.' if `which brew`.empty?
      cmd = "bundle exec build #{project} #{platform} --engine local"
    else
      cmd = "bundle exec build #{project} #{platform} --engine docker"
    end

    puts "Running #{cmd}"
    exitcode = nil
    Open3.popen2e(cmd) do |_stdin, stdout_stderr, thread|
      stdout_stderr.each { |line| puts line }
      exitcode = thread.value.exitstatus
      puts "Command finished with status #{exitcode}"
    end
    exit exitcode
  end
end
