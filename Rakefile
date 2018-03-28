require 'rspec'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

task :test => %i[spec rubocop]
RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new
