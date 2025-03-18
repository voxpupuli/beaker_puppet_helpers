# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'beaker_puppet_helpers'
  s.version     = '2.0.0'
  s.authors     = ['Vox Pupuli']
  s.email       = ['voxpupuli@groups.io']
  s.homepage    = 'https://github.com/voxpupuli/beaker_puppet_helpers'
  s.summary     = "Beaker's Puppet DSL Extension Helpers"
  s.description = 'For use for the Beaker acceptance testing tool'
  s.license     = 'Apache-2.0'

  s.required_ruby_version = '>= 2.7', '< 4'

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ['lib']

  # Run time dependencies
  s.add_dependency 'beaker', '>= 5.8.1', '< 7'
  s.add_dependency 'puppet-modulebuilder', '>= 0.3', '< 3'
  # we need to declare both dependencies explicitly on Ruby 3.4+
  s.add_dependency 'base64', '~> 0.2.0'
  s.add_dependency 'benchmark', '~> 0.4.0'
end
