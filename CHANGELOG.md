# Changelog

All notable changes to this project will be documented in this file.

## [1.4.0](https://github.com/voxpupuli/beaker_puppet_helpers/tree/1.4.0) (2024-05-28)

[Full Changelog](https://github.com/voxpupuli/beaker_puppet_helpers/compare/1.3.0...1.4.0)

**Implemented enhancements:**

- beaker: Allow 6.x [\#47](https://github.com/voxpupuli/beaker_puppet_helpers/pull/47) ([bastelfreak](https://github.com/bastelfreak))
- Use tmpfile extension [\#3](https://github.com/voxpupuli/beaker_puppet_helpers/pull/3) ([ekohl](https://github.com/ekohl))

**Merged pull requests:**

- .gitignore: add .bundle [\#46](https://github.com/voxpupuli/beaker_puppet_helpers/pull/46) ([bastelfreak](https://github.com/bastelfreak))
- voxpupuli-rubocop: Require 2.7.0 [\#45](https://github.com/voxpupuli/beaker_puppet_helpers/pull/45) ([bastelfreak](https://github.com/bastelfreak))

## [1.3.0](https://github.com/voxpupuli/beaker_puppet_helpers/tree/1.3.0) (2024-05-02)

[Full Changelog](https://github.com/voxpupuli/beaker_puppet_helpers/compare/1.2.1...1.3.0)

**Implemented enhancements:**

- Add Ruby 3.3 to CI [\#44](https://github.com/voxpupuli/beaker_puppet_helpers/pull/44) ([traylenator](https://github.com/traylenator))
- New beaker helper `bolt_supported?` to show bolt availability [\#42](https://github.com/voxpupuli/beaker_puppet_helpers/pull/42) ([traylenator](https://github.com/traylenator))

## [1.2.1](https://github.com/voxpupuli/beaker_puppet_helpers/tree/1.2.1) (2024-01-08)

[Full Changelog](https://github.com/voxpupuli/beaker_puppet_helpers/compare/1.2.0...1.2.1)

**Fixed bugs:**

- shell escape Puppet command options [\#40](https://github.com/voxpupuli/beaker_puppet_helpers/pull/40) ([ekohl](https://github.com/ekohl))
- FreeBSD has the Puppet major version in the package name [\#39](https://github.com/voxpupuli/beaker_puppet_helpers/pull/39) ([evgeni](https://github.com/evgeni))

## [1.2.0](https://github.com/voxpupuli/beaker_puppet_helpers/tree/1.2.0) (2023-10-17)

[Full Changelog](https://github.com/voxpupuli/beaker_puppet_helpers/compare/1.1.1...1.2.0)

**Implemented enhancements:**

- Always use puppet-agent for Debian 12+ & Ubuntu 23.04+ [\#37](https://github.com/voxpupuli/beaker_puppet_helpers/pull/37) ([ekohl](https://github.com/ekohl))

## [1.1.1](https://github.com/voxpupuli/beaker_puppet_helpers/tree/1.1.1) (2023-06-16)

[Full Changelog](https://github.com/voxpupuli/beaker_puppet_helpers/compare/1.1.0...1.1.1)

**Fixed bugs:**

- fix typo in EL package selection [\#32](https://github.com/voxpupuli/beaker_puppet_helpers/pull/32) ([bastelfreak](https://github.com/bastelfreak))

**Merged pull requests:**

- CI: Run on PRs+merges to master [\#33](https://github.com/voxpupuli/beaker_puppet_helpers/pull/33) ([bastelfreak](https://github.com/bastelfreak))
- README.md: Correct link to CI jobs [\#30](https://github.com/voxpupuli/beaker_puppet_helpers/pull/30) ([bastelfreak](https://github.com/bastelfreak))
- GCG: Add faraday-retry dep [\#29](https://github.com/voxpupuli/beaker_puppet_helpers/pull/29) ([bastelfreak](https://github.com/bastelfreak))

## [1.1.0](https://github.com/voxpupuli/beaker_puppet_helpers/tree/1.1.0) (2023-06-01)

[Full Changelog](https://github.com/voxpupuli/beaker_puppet_helpers/compare/1.0.1...1.1.0)

**Implemented enhancements:**

- Add support for `--show_diff` [\#27](https://github.com/voxpupuli/beaker_puppet_helpers/pull/27) ([smortex](https://github.com/smortex))

## [1.0.1](https://github.com/voxpupuli/beaker_puppet_helpers/tree/1.0.1) (2023-05-10)

[Full Changelog](https://github.com/voxpupuli/beaker_puppet_helpers/compare/1.0.0...1.0.1)

**Fixed bugs:**

- puppet-modulebuilder: Allow 1.x [\#25](https://github.com/voxpupuli/beaker_puppet_helpers/pull/25) ([bastelfreak](https://github.com/bastelfreak))

## [1.0.0](https://github.com/voxpupuli/beaker_puppet_helpers/tree/1.0.0) (2023-05-05)

[Full Changelog](https://github.com/voxpupuli/beaker_puppet_helpers/compare/5cc9e2e0e2a6a3541502bb1aae961071a8b96157...1.0.0)

**Implemented enhancements:**

- Send arguments as keyword arguments & Test on Ruby 3.1 and 3.2 [\#19](https://github.com/voxpupuli/beaker_puppet_helpers/pull/19) ([ekohl](https://github.com/ekohl))

**Merged pull requests:**

- puppet-modulebuilder: Allow 1.x [\#23](https://github.com/voxpupuli/beaker_puppet_helpers/pull/23) ([bastelfreak](https://github.com/bastelfreak))
- add dummy CI job we can depend on [\#22](https://github.com/voxpupuli/beaker_puppet_helpers/pull/22) ([bastelfreak](https://github.com/bastelfreak))
- Add .vendor and vendor to .gitignore [\#21](https://github.com/voxpupuli/beaker_puppet_helpers/pull/21) ([bastelfreak](https://github.com/bastelfreak))
- CI: Build gems with strictness and verbosity [\#20](https://github.com/voxpupuli/beaker_puppet_helpers/pull/20) ([bastelfreak](https://github.com/bastelfreak))
- Fix RSpec/RepeatedDescription [\#18](https://github.com/voxpupuli/beaker_puppet_helpers/pull/18) ([ekohl](https://github.com/ekohl))
- Allow beaker 4 [\#17](https://github.com/voxpupuli/beaker_puppet_helpers/pull/17) ([ekohl](https://github.com/ekohl))
- Pass arguments as array in fact\_on [\#16](https://github.com/voxpupuli/beaker_puppet_helpers/pull/16) ([ekohl](https://github.com/ekohl))
- Use instance doubles in tests [\#15](https://github.com/voxpupuli/beaker_puppet_helpers/pull/15) ([ekohl](https://github.com/ekohl))
- Run acceptance tests on Ubuntu 20.04 [\#14](https://github.com/voxpupuli/beaker_puppet_helpers/pull/14) ([bastelfreak](https://github.com/bastelfreak))
- Fix various RSpec cops before enabling rubocop-rspec [\#13](https://github.com/voxpupuli/beaker_puppet_helpers/pull/13) ([ekohl](https://github.com/ekohl))
- Drop Ruby 2.5 and 2.6 support [\#12](https://github.com/voxpupuli/beaker_puppet_helpers/pull/12) ([ekohl](https://github.com/ekohl))
- Make RuboCop mostly happy [\#11](https://github.com/voxpupuli/beaker_puppet_helpers/pull/11) ([ekohl](https://github.com/ekohl))
- Simplify variable setting [\#9](https://github.com/voxpupuli/beaker_puppet_helpers/pull/9) ([ekohl](https://github.com/ekohl))
- Use rubocop config from voxpupuli-rubocop [\#6](https://github.com/voxpupuli/beaker_puppet_helpers/pull/6) ([bastelfreak](https://github.com/bastelfreak))
- dependabot: check for github actions and gems [\#5](https://github.com/voxpupuli/beaker_puppet_helpers/pull/5) ([bastelfreak](https://github.com/bastelfreak))
- Add CI and release workflow [\#1](https://github.com/voxpupuli/beaker_puppet_helpers/pull/1) ([ekohl](https://github.com/ekohl))



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
