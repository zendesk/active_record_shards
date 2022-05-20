Gem::Specification.new "active_record_shards", "3.19.1" do |s|
  s.authors     = ["Benjamin Quorning", "Gabe Martin-Dempesy", "Pierre Schambacher", "Mick Staugaard", "Eric Chapweske", "Ben Osheroff"]
  s.email       = ["bquorning@zendesk.com", "gabe@zendesk.com", "pschambacher@zendesk.com", "mick@staugaard.com"]
  s.homepage    = "https://github.com/zendesk/active_record_shards"
  s.summary     = "Simple database switching for ActiveRecord."
  s.description = "Easily run queries on shard and replica databases."
  s.license     = "MIT"

  s.required_ruby_version = ">= 2.6"

  s.add_runtime_dependency("activerecord", ">= 6.0", "< 6.1")
  s.add_runtime_dependency("activesupport", ">= 6.0", "< 6.1")

  s.add_development_dependency("bump")
  s.add_development_dependency("minitest", ">= 5.10.0")
  s.add_development_dependency("minitest-rg")
  s.add_development_dependency("mocha", ">= 1.4.0")
  s.add_development_dependency("mysql2")
  s.add_development_dependency("rake", '~> 12.0')
  s.add_development_dependency("rubocop", "~> 0.77.0")
  s.add_development_dependency("rubocop-minitest", "~> 0.5.0")
  s.add_development_dependency("rubocop-performance", "~> 1.5.1")

  s.files = Dir["lib/**/*"] + ["README.md"]
end
