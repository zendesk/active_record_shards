require 'bundler'
require "appraisal"
require 'yaggy'

Yaggy.gem('active_record_shards.gemspec', :push_gem => true)

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

task :default => :test
