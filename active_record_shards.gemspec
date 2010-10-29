# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "active_record_shards"
  s.version     = "1.0.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Mick Staugaard", "Eric Chapweske"]
  s.email       = ["mick@staugaard.com", "eac@zendesk.com"]
  s.homepage    = "http://github.com/eac/replica"
  s.summary     = "Simple database switching for ActiveRecord."
  s.description = "Easily run queries on replicated/slave databases."

  s.add_runtime_dependency("activerecord", "~> 2.3.5")

  s.add_development_dependency("rake")
  s.add_development_dependency("bundler")
  s.add_development_dependency("shoulda")
  s.add_development_dependency("mocha")
  s.add_development_dependency("mysql")
  s.add_development_dependency("ruby-debug")

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
