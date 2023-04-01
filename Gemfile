# frozen_string_literal: true

source ENV['GEM_SOURCE'] || 'https://rubygems.org'

gemspec

gem 'rubocop', require: false
gem 'rubocop-rake', require: false
gem 'rubocop-rspec', require: false

case ENV.fetch('BEAKER_HYPERVISOR', nil)
when 'docker'
  gem 'beaker-docker'
when 'vagrant', 'vagrant_libvirt'
  gem 'beaker-vagrant'
end

group :release do
  gem 'github_changelog_generator', require: false
end
