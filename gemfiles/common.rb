# frozen_string_literal: true
source 'https://rubygems.org'

gemspec path: Bundler.root.to_s.sub('/gemfiles', '')

group :test do
  gem 'byebug', platforms: [:mri]
  gem 'ar_mysql_flexmaster'
end
