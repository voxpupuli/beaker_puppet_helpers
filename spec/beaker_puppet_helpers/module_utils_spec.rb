# frozen_string_literal: true

require 'spec_helper'

class ClassMixedWithDSLInstallUtils
  include Beaker::DSL::Patterns
  include BeakerPuppetHelpers::ModuleUtils

  def logger
    @logger ||= RSpec::Mocks::Double.new('Beaker::Logger').as_null_object
  end
end

describe BeakerPuppetHelpers::ModuleUtils do
  subject(:dsl) { ClassMixedWithDSLInstallUtils.new }

  let(:host) { double('Beaker::Host') }

  describe '#install_puppet_module_via_pmt_on' do
    let(:default_module_install_opts) { nil }

    before do
      allow(host).to receive(:[]).with(:default_module_install_opts).and_return(default_module_install_opts)
    end

    it 'installs module via puppet module tool' do
      expect(Beaker::PuppetCommand).to receive(:new).with('module', %w[install test], {}).once
      expect(dsl).to receive(:on).with(host, anything).once

      dsl.install_puppet_module_via_pmt_on(host, 'test')
    end

    it 'accepts the version parameter' do
      expect(Beaker::PuppetCommand).to receive(:new).with('module', %w[install test], { version: '1.2.3' }).once
      expect(dsl).to receive(:on).with(host, anything).once

      dsl.install_puppet_module_via_pmt_on(host, 'test', '1.2.3')
    end

    it 'accepts the module_repository parameter' do
      expect(Beaker::PuppetCommand).to receive(:new).with('module', %w[install test], { module_repository: 'http://forge.example.com' }).once
      expect(dsl).to receive(:on).with(host, anything).once

      dsl.install_puppet_module_via_pmt_on(host, 'test', nil, 'http://forge.example.com')
    end

    it 'accepts the version and module_repository parameters' do
      expect(Beaker::PuppetCommand).to receive(:new).with('module', %w[install test], { version: '1.2.3', module_repository: 'http://forge.example.com' }).once
      expect(dsl).to receive(:on).with(host, anything).once

      dsl.install_puppet_module_via_pmt_on(host, 'test', '1.2.3', 'http://forge.example.com')
    end

    context 'with host with trace option' do
      let(:default_module_install_opts) { { trace: nil } }

      it 'takes the trace option and passes it down correctly' do
        expect(Beaker::PuppetCommand).to receive(:new).with('module', %w[install test], { trace: nil }).once
        expect(dsl).to receive(:on).with(host, anything).once

        dsl.install_puppet_module_via_pmt_on(host, 'test')
      end
    end

    context 'with host with module_repository set' do
      let(:default_module_install_opts) { { module_repository: 'http://forge.example.com' } }

      it 'passes it down' do
        expect(Beaker::PuppetCommand).to receive(:new).with('module', %w[install test], { module_repository: 'http://forge.example.com' }).once
        expect(dsl).to receive(:on).with(host, anything).once

        dsl.install_puppet_module_via_pmt_on(host, 'test')
      end

      it 'argument overrides host defaults' do
        expect(Beaker::PuppetCommand).to receive(:new).with('module', %w[install test], { module_repository: 'http://other.example.com' }).once
        expect(dsl).to receive(:on).with(host, anything).once

        dsl.install_puppet_module_via_pmt_on(host, 'test', nil, 'http://other.example.com')
      end
    end
  end

  describe '#install_local_module_on' do
    let(:builder) { double('Puppet::Modulebuilder::Builder') }

    it 'builds and copies the module' do
      expect(File).to receive(:realpath).with('.').and_return('/path/to/module')
      allow(File).to receive(:unlink).with('/path/to/tarball')
      expect(Puppet::Modulebuilder::Builder).to receive(:new).with('/path/to/module').and_return(builder)
      expect(builder).to receive(:build).and_return('/path/to/tarball')

      expect(host).to receive(:tmpfile).with('puppet_module').and_return('temp')
      expect(host).to receive(:do_scp_to).with('/path/to/tarball', 'temp', {})
      expect(dsl).to receive(:install_puppet_module_via_pmt_on).with(host, 'temp')
      expect(host).to receive(:rm_rf).with('temp')

      dsl.install_local_module_on(host)
    end
  end
end
