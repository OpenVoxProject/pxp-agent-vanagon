def run_command(cmd)
  output, status = Open3.capture2e(cmd)
  abort "Command failed! Command: #{cmd}, Output: #{output}" unless status.exitstatus.zero?
  output.chomp
end

Dir.glob(File.join('tasks/**/*.rake')).each { |file| load file }

desc 'run static analysis with rubocop'
task(:rubocop) do
  require 'rubocop'
  cli = RuboCop::CLI.new
  exit_code = cli.run(%w[--display-cop-names --format simple])
  raise 'RuboCop detected offenses' if exit_code != 0
end
