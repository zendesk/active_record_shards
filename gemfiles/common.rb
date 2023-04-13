# frozen_string_literal: true

source "https://rubygems.org"

gemspec(path: Bundler.root.to_s.sub("/gemfiles", ""))

group :test do
  gem "pry-byebug", platforms: [:mri]
end

gem "benchmark-ips"
gem "debug", ">= 1.0.0"
gem "rubocop", "~> 1.50.0"
gem "rubocop-minitest", "~> 0.30.0"
gem "rubocop-performance", "~> 1.17.0"
