# frozen_string_literal: true

source ENV['GEM_SOURCE'] || 'https://rubygems.org'

gemspec

case ENV.fetch('BEAKER_HYPERVISOR', nil)
when 'docker'
  gem 'beaker-docker'
when 'vagrant', 'vagrant_libvirt'
  gem 'beaker-vagrant'
end

group :release do
  gem 'github_changelog_generator', require: false
end
