# frozen_string_literal: true

module BeakerPuppetHelpers
  autoload :DSL, File.join(__dir__, 'beaker_puppet_helpers', 'dsl.rb')
  autoload :InstallUtils, File.join(__dir__, 'beaker_puppet_helpers', 'install_utils.rb')
  autoload :ModuleUtils, File.join(__dir__, 'beaker_puppet_helpers', 'module_utils.rb')
end

require 'beaker'
Beaker::DSL.register(BeakerPuppetHelpers::DSL)
Beaker::DSL.register(BeakerPuppetHelpers::ModuleUtils)
