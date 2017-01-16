require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "spec/unit/**/*_spec.rb"
end

RSpec::Core::RakeTask.new(:integration_spec) do |t|
  t.pattern = "spec/integration/**/*_spec.rb"
end

task :default => :spec
