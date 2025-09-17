# frozen_string_literal: true

require 'beaker_puppet_helpers'

# require 'pp' statement needed before fakefs, otherwise they can collide. Ref:
#   https://github.com/fakefs/fakefs#fakefs-----typeerror-superclass-mismatch-for-class-file
require 'pp'
require 'fakefs/spec_helpers'
require 'helpers'

RSpec.configure do |config|
  config.include FakeFS::SpecHelpers
  config.include HostHelpers
end
