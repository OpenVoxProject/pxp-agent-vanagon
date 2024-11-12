source ENV['GEM_SOURCE'] || 'https://rubygems.org'

def location_for(place)
  case place
  when /^((?:git[:@]|https:)[^#]*)#(.*)/
    [{ git: Regexp.last_match(1), branch: Regexp.last_match(2), require: false }]
  when %r{^file://(.*)}
    ['>= 0', { path: File.expand_path(Regexp.last_match(1)), require: false }]
  else
    [place, { require: false }]
  end
end

gem 'artifactory'
gem 'json'
gem 'octokit'
gem 'packaging', *location_for(ENV['PACKAGING_LOCATION'] || '~> 0.105')
gem 'rake'
gem 'rubocop', '~> 1.5'
# We must do this here in the plumbing branch so that when the build script
# runs with VANAGON_LOCATION set, it already has the right gem installed.
# Bundler seems to get confused when the rake tasks runs with a different
# vanagon version in the bundle.
gem 'vanagon', *location_for("https://github.com/overlookinfra/vanagon#main")

eval_gemfile("#{__FILE__}.local") if File.exist?("#{__FILE__}.local")
