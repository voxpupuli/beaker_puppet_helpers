# frozen_string_literal: true

source ENV['GEM_SOURCE'] || 'https://rubygems.org'

gemspec

gem 'rake', '~> 13.0', groups: %i[development test release]

group :development do
  gem 'rdoc'
  gem 'redcarpet'
  gem 'yard'
end

group :rubocop do
  gem 'voxpupuli-rubocop', '~> 3.1.0'
end

group :test do
  gem 'rspec', '~> 3.0'
end

case ENV.fetch('BEAKER_HYPERVISOR', nil)
when 'docker'
  gem 'beaker-docker'
when 'vagrant', 'vagrant_libvirt'
  gem 'beaker-vagrant'
end

group :release, optional: true do
  gem 'faraday-retry', require: false
  gem 'github_changelog_generator', require: false
end
