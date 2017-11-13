Gem::Specification.new "active_record_shards", "4.0.0.beta8" do |s|
  s.authors     = ["Mick Staugaard", "Eric Chapweske", "Ben Osheroff"]
  s.email       = ["mick@staugaard.com", "eac@zendesk.com", "ben@gimbo.net"]
  s.homepage    = "https://github.com/zendesk/active_record_shards"
  s.summary     = "Simple database switching for ActiveRecord."
  s.description = "Easily run queries on shard and slave databases."
  s.license     = "MIT"

  s.required_ruby_version = "~> 2.0"

  s.add_runtime_dependency("activerecord", "~> 5.0")
  s.add_runtime_dependency("activesupport", "~> 5.0")

  s.add_development_dependency("bump")
  s.add_development_dependency("minitest")
  s.add_development_dependency("minitest-rg")
  s.add_development_dependency("mocha")
  s.add_development_dependency("mysql2")
  s.add_development_dependency("phenix", ">= 0.2.0")
  s.add_development_dependency("rake", '~> 12.0')
  s.add_development_dependency("rubocop", "0.51.0")
  s.add_development_dependency("wwtd")

  s.files = Dir["lib/**/*"] + ["README.md"]
end
