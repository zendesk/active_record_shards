Gem::Specification.new "active_record_shards", "3.5.0-alpha" do |s|
  s.authors     = ["Mick Staugaard", "Eric Chapweske", "Ben Osheroff"]
  s.email       = ["mick@staugaard.com", "eac@zendesk.com", "ben@gimbo.net"]
  s.homepage    = "https://github.com/zendesk/active_record_shards"
  s.summary     = "Simple database switching for ActiveRecord."
  s.description = "Easily run queries on shard and slave databases."
  s.license     = "MIT"

  s.add_runtime_dependency("activerecord", ">= 4.1.0", "< 5.0")
  s.add_runtime_dependency("activesupport", ">= 4.1.0", "< 5.0")

  s.add_development_dependency("wwtd")
  s.add_development_dependency("rake")
  s.add_development_dependency("mysql2")
  s.add_development_dependency("bump")
  s.add_development_dependency("minitest")
  s.add_development_dependency("minitest-rg")
  s.add_development_dependency("mocha")

  s.files        = Dir["lib/**/*"] + ["README.md"]
end
