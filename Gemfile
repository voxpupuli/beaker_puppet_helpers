# frozen_string_literal: true

source ENV['GEM_SOURCE'] || 'https://rubygems.org'

gemspec

gem 'rubocop'
gem 'rubocop-rake'
gem 'rubocop-rspec'

case ENV['BEAKER_HYPERVISOR']
when 'docker'
  gem 'beaker-docker'
when 'vagrant', 'vagrant_libvirt'
  gem 'beaker-vagrant'
end

group :release do
  gem 'github_changelog_generator', require: false
end
