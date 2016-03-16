require 'bundler/setup'
require 'bump/tasks'
require 'wwtd/tasks'

Bundler::GemHelper.install_tasks

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.pattern = './test/**/*_test.rb'
  test.verbose = false
  test.warning = false
end

task :default => "wwtd:local"

task :console do
  require 'irb'
  require 'irb/completion'
  require 'active_record_shards'
  ARGV.clear
  IRB.start
end
