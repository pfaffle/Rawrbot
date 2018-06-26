require 'rspec'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

task test: %i[spec rubocop]
RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new
RuboCop::RakeTask.new(:rubocop_autocorrect) do |task|
  task.options = ['-a']
end
