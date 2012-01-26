# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "active_record_shards"
  s.version     = "2.5.7"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Mick Staugaard", "Eric Chapweske", "Ben Osheroff"]
  s.email       = ["mick@staugaard.com", "eac@zendesk.com", "ben@gimbo.net"]
  s.homepage    = "http://github.com/staugaard/active_record_shards"
  s.summary     = "Simple database switching for ActiveRecord."
  s.description = "Easily run queries on shard and slave databases."

  s.add_runtime_dependency("activerecord",  ">= 2.3.5", "< 3.2")

  s.add_development_dependency("rake")
  s.add_development_dependency("mysql")
  s.add_development_dependency("bundler")
  s.add_development_dependency("shoulda")
  s.add_development_dependency("mocha")
  s.add_development_dependency("appraisal")

  if RUBY_VERSION < "1.9"
    s.add_development_dependency("ruby-debug")
  else
    s.add_development_dependency("ruby-debug19")
  end

  s.files        = Dir.glob("lib/**/*") + %w(README.md)
  s.test_files   = Dir.glob("test/**/*")
  s.require_path = 'lib'
end
