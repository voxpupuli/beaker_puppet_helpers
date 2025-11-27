# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'beaker_puppet_helpers'
  s.version     = '3.1.1'
  s.authors     = ['Vox Pupuli']
  s.email       = ['voxpupuli@groups.io']
  s.homepage    = 'https://github.com/voxpupuli/beaker_puppet_helpers'
  s.summary     = "Beaker's Puppet DSL Extension Helpers"
  s.description = 'For use for the Beaker acceptance testing tool'
  s.license     = 'Apache-2.0'

  s.required_ruby_version = '>= 3.2'

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ['lib']

  # Run time dependencies
  s.add_dependency 'beaker', '>= 5.8.1', '< 8'
  s.add_dependency 'nokogiri', '~> 1.18', '>= 1.18.10'
  s.add_dependency 'open-uri', '< 0.6'
  s.add_dependency 'puppet-modulebuilder', '>= 0.3', '< 3'

  s.add_development_dependency 'voxpupuli-rubocop', '~> 5.0.0'
end
