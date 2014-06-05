require 'bundler/setup'
require "appraisal"
require "bump/tasks"

Bundler::GemHelper.install_tasks

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.pattern = './test/**/*_test.rb'
  test.verbose = true
end

task :default do
  sh "appraisal install && appraisal rake test"
end

task :console do
  require 'irb'
  require 'irb/completion'
  require 'active_record_shards'
  ARGV.clear
  IRB.start
end
