# Beaker Puppet Helpers

The purpose of this library is to hold Puppet-specific info & DSL methods.
This includes all helper & installer methods.

This is based on [beaker-puppet](https://github.com/voxpupuli/beaker-puppet) and
[beaker-puppet_install_helper](https://github.com/puppetlabs/beaker-puppet_install_helper)
but is a reduced set.

## How Do I Use This?

You will need to include beaker-puppet alongside Beaker in your Gemfile or project.gemspec. E.g.

```ruby
# Gemfile
gem 'beaker_puppet_helpers', '~> 0.1.0'

# project.gemspec
s.add_runtime_dependency 'beaker_puppet_helpers', '~> 0.1.0'
```

For DSL Extension Libraries, you must also ensure that you `require` the
library in your test files. You can do this manually in individual test files
or in a test helper (if you have one). You can [use
`Bundler.require()`](https://bundler.io/v1.16/guides/groups.html) to require
the library automatically. To explicitly require it:

```ruby
require 'beaker_puppet_helpers'
```

Doing this will include (automatically) the beaker_puppet_helpers DSL methods
in the beaker DSL. Then you can call beaker_puppet_helpers methods.

## How Do I Test This?

### Unit / Spec Testing

You can run the spec testing using the rake task `spec`. You can also run
`rspec` directly.

### Acceptance Testing

Acceptance testing can be run using the `acceptance` rake test.

Note in the above rake tasks that there are some environment variables that you
can use to customize your run. For specifying your System Under Test (SUT)
environment, you can use `BEAKER_HOSTS`, passing a file path to a beaker hosts
file or a beaker-hostgenerator value. You can also specify the tests that get
executed with the `TESTS` environment variable.

## License

This gem is licensed under the Apache-2 license.

## Release information

To make a new release, please do:
* update the version in `beaker_puppet_helpers.gemspec`
* Install gems with `bundle install --with release --path .vendor`
* generate the changelog with `bundle exec rake changelog`
* Check if the new version matches the closed issues/PRs in the changelog
* Create a PR with it
* After it got merged, push a tag. GitHub actions will do the actual release to Rubygems and GitHub Packages
