# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "active_record_shards"
  s.version     = "1.0.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Mick Staugaard", "Eric Chapweske"]
  s.email       = ["mick@staugaard.com", "eac@zendesk.com"]
  s.homepage    = "http://github.com/staugaard/active_record_shards"
  s.summary     = "Simple database switching for ActiveRecord."
  s.description = "Easily run queries on shard and slave databases."

  s.add_runtime_dependency("activerecord", "~> 2.3.5")

  s.add_development_dependency("rake")
  s.add_development_dependency("bundler")
  s.add_development_dependency("shoulda")
  s.add_development_dependency("mocha")

  if RUBY_PLATFORM == 'java'
    s.add_development_dependency("mysql")
  else
    if RUBY_VERSION < "1.9"
      s.add_development_dependency("ruby-debug")
    else
      s.add_development_dependency("ruby-debug19")
    end
  end

  s.files        = Dir.glob("lib/**/*") + %w(README.rdoc)
  s.test_files   = Dir.glob("test/**/*")
  s.require_path = 'lib'
end
