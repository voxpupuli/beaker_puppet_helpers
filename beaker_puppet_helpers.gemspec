# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'beaker_puppet_helpers'
  s.version     = '0.1.0'
  s.authors     = ['Vox Pupuli']
  s.email       = ['voxpupuli@groups.io']
  s.homepage    = 'https://github.com/voxpupuli/beaker_puppet_helpers'
  s.summary     = "Beaker's Puppet DSL Extension Helpers"
  s.description = 'For use for the Beaker acceptance testing tool'
  s.license     = 'Apache2'

  s.required_ruby_version = '>= 2.5', '< 4'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ['lib']

  # Testing dependencies
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'rspec', '~> 3.0'

  # Documentation dependencies
  s.add_development_dependency 'redcarpet'
  s.add_development_dependency 'yard'

  # Run time dependencies
  s.add_runtime_dependency 'beaker', '~> 4.1'
  s.add_runtime_dependency 'puppet-modulebuilder', '~> 0.3'
end
