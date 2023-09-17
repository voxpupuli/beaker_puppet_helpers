# frozen_string_literal: true

require 'beaker/command'
require 'puppet/modulebuilder'

module BeakerPuppetHelpers
  # Methods to help install puppet modules
  module ModuleUtils
    # Install the desired module with the Puppet Module Tool (PMT) on a given host
    #
    # @param [Beaker::Host, Array<Beaker::Host>, String, Symbol] hosts
    #   One or more hosts to act upon, or a role (String or Symbol) that
    #   identifies one or more hosts.
    # @param [String] module_name
    #   The short name of the module to be installed
    # @param [String] version
    #   The version of the module to be installed
    # @param [String] module_repository
    #   An optional module repository to install from
    def install_puppet_module_via_pmt_on(hosts, module_name, version = nil, module_repository = nil)
      block_on hosts do |host|
        puppet_opts = {}
        puppet_opts.merge!(host[:default_module_install_opts]) if host[:default_module_install_opts]
        puppet_opts[:version] = version if version
        puppet_opts[:module_repository] = module_repository if module_repository

        on host, Beaker::PuppetCommand.new('module', ['install', module_name], puppet_opts)
      end
    end

    # Install local module for acceptance testing
    #
    # This uses puppet-modulebuilder to build the module located at source
    # and then copies it to the hosts. There it runs puppet module install.
    #
    # @param [Beaker::Host, Array<Beaker::Host>, String, Symbol] hosts
    #   One or more hosts to act upon, or a role (String or Symbol) that
    #   identifies one or more hosts.
    # @param [String] source
    #   The directory where the module sits
    def install_local_module_on(hosts, source = '.')
      builder = Puppet::Modulebuilder::Builder.new(File.realpath(source))
      source_path = builder.build
      begin
        block_on hosts do |host|
          target_file = host.tmpfile('puppet_module')
          begin
            host.do_scp_to(source_path, target_file, {})
            install_puppet_module_via_pmt_on(host, target_file)
          ensure
            host.rm_rf(target_file)
          end
        end
      ensure
        File.unlink(source_path) if source_path
      end
    end
  end
end
