# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "active_record_shards"
  s.version     = "2.7.5"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Mick Staugaard", "Eric Chapweske", "Ben Osheroff"]
  s.email       = ["mick@staugaard.com", "eac@zendesk.com", "ben@gimbo.net"]
  s.homepage    = "http://github.com/zendesk/active_record_shards"
  s.summary     = "Simple database switching for ActiveRecord."
  s.description = "Easily run queries on shard and slave databases."
  s.license     = "MIT"

  s.add_runtime_dependency("activerecord",  ">= 2.3.5", "< 3.3")

  s.files        = Dir.glob("lib/**/*") + %w(README.md)
  s.test_files   = Dir.glob("test/**/*") - ["test/test.log"]
  s.require_path = 'lib'
end
