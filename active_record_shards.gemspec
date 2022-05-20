Gem::Specification.new "active_record_shards", "3.19.1" do |s|
  s.authors     = ["Benjamin Quorning", "Gabe Martin-Dempesy", "Pierre Schambacher", "Mick Staugaard", "Eric Chapweske", "Ben Osheroff"]
  s.email       = ["bquorning@zendesk.com", "gabe@zendesk.com", "pschambacher@zendesk.com", "mick@staugaard.com"]
  s.homepage    = "https://github.com/zendesk/active_record_shards"
  s.summary     = "Simple database switching for ActiveRecord."
  s.description = "Easily run queries on shard and replica databases."
  s.license     = "MIT"

  s.required_ruby_version = ">= 2.5"

  s.add_runtime_dependency("activerecord", "~> 6.1.0")
  s.add_runtime_dependency("activesupport", "~> 6.1.0")

  s.files = Dir["lib/**/*"] + ["README.md"]
end
