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

    engine = platform =~ /^(osx|windows)-/ ? 'local' : 'docker'
    cmd = "bundle exec build #{project} #{platform} --engine #{engine}"

    FileUtils.rm_rf('C:/ProgramFiles64Folder/') if platform =~ /^windows-/

    run_command(cmd, silent: false, print_command: true, report_status: true)
  end
end
