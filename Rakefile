require 'bundler/setup'
require "appraisal"
require "bump/tasks"

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.pattern = './test/**/*_test.rb'
  test.verbose = true
end

task :default do
  sh "rake appraisal:install && rake appraisal test"
end
