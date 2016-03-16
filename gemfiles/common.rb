source 'https://rubygems.org'

gemspec path: Bundler.root.to_s.sub('/gemfiles', '')

gem "byebug", platforms: [:mri]
