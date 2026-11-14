# frozen_string_literal: true

require 'spec_helper'

describe BeakerPuppetHelpers::InstallUtils do
  describe '.install_puppet_release_repo_on' do
    let(:host) { instance_double(Beaker::Host) }
    let(:packaging_platform) { Beaker::Platform.new(platform) }

    before { allow(host).to receive(:[]).with('packaging_platform').and_return(packaging_platform) }

    context 'with default options' do
      subject(:install_puppet_release_repo_on) { described_class.install_puppet_release_repo_on(host) }

      context 'with EL 7 platform' do
        let(:platform) { 'el-7-x86_64' }

        it 'installs from the correct url' do
          expect(host).to receive(:install_package).with('https://yum.puppet.com/puppet-release-el-7.noarch.rpm')

          install_puppet_release_repo_on
        end
      end

      context 'with Fedora 34 platform' do
        let(:platform) { 'fedora-34-x86_64' }

        it 'installs from the correct url' do
          expect(host).to receive(:install_package).with('https://yum.puppet.com/puppet-release-fedora-34.noarch.rpm')

          install_puppet_release_repo_on
        end
      end

      context 'with SLES 15 platform' do
        let(:platform) { 'sles-15-x86_64' }

        it 'installs from the correct url and calls rpm --import' do
          expect(host).to receive(:install_package).with('https://yum.puppet.com/puppet-release-sles-15.noarch.rpm')

          expect(described_class).to receive(:wget_on).with(host, 'https://yum.puppet.com/RPM-GPG-KEY-puppet').and_yield('puppet.gpg').once
          expect(Beaker::Command).to receive(:new).with("rpm --import 'puppet.gpg'").and_return("rpm --import 'puppet.gpg'").once
          expect(host).to receive(:exec).with("rpm --import 'puppet.gpg'").once

          expect(described_class).to receive(:wget_on).with(host, 'https://yum.puppet.com/RPM-GPG-KEY-puppet-20250406').and_yield('puppet-20250406.gpg').once
          expect(Beaker::Command).to receive(:new).with("rpm --import 'puppet-20250406.gpg'").and_return("rpm --import 'puppet-20250406.gpg'").once
          expect(host).to receive(:exec).with("rpm --import 'puppet-20250406.gpg'").once

          install_puppet_release_repo_on
        end
      end

      context 'with Debian 11 platform' do
        let(:platform) { 'debian-11-x86_64' }

        before { allow(host).to receive(:[]).with('platform').and_return(packaging_platform) }

        it 'installs from the correct url and runs apt-get update' do
          expect(described_class).to receive(:wget_on).with(host, 'https://apt.puppet.com/puppet-release-bullseye.deb').and_yield('filename.deb')
          expect(host).to receive(:install_package).with('filename.deb')
          expect(Beaker::Command).to receive(:new).with('apt-get update').and_return('apt-get update')
          expect(host).to receive(:exec).with('apt-get update')
          expect(host).to receive(:add_env_var).with('PATH', '/opt/puppetlabs/bin')

          install_puppet_release_repo_on
        end
      end
    end
  end

  describe '.install_openvox_agent_dmg_on' do
    subject(:install_openvox_agent_dmg_on) { described_class.install_openvox_agent_dmg_on(host, 'openvox9') }

    let(:host) { instance_double(Mac::Host) }
    let(:url) { 'https://downloads.voxpupuli.org/mac/openvox9/' }
    let(:files) do
      %w[
        openbolt-9.0.0-1.macos.all.arm64.dmg
        openvox-agent-9.0.0~rc1-1.macos.all.arm64.dmg
        openvox-agent-9.2.1-1.macos.all.arm64.dmg
        openvox-agent-9.9.0-1.macos.all.arm64.dmg
        openvox-agent-9.9.0-2.macos.all.arm64.dmg
        openvox-agent-9.9.0-1.macos.all.x86_64.dmg
        openvox-agent-9.10.0-1.macos.all.x86_64.dmg
      ]
    end
    let(:index_html) { "<html><body>#{files.map { |file| %(<a href="#{file}">#{file}</a>) }.join}</body></html>" }

    before do
      allow(host).to receive(:[]).with('platform').and_return(Beaker::Platform.new(platform))
      allow(Net::HTTP).to receive(:get_response).with(URI.parse(url))
                                                .and_return(instance_double(Net::HTTPOK, is_a?: true, body: index_html))
    end

    context 'with an arm64 host' do
      let(:platform) { 'osx-15-arm64' }

      it 'installs the newest release and build for its architecture' do
        expect(host).to receive(:generic_install_dmg).with("#{url}openvox-agent-9.9.0-2.macos.all.arm64.dmg",
                                                           'openvox-agent-9.9.0', 'openvox-agent-9.9.0-2-installer.pkg')

        install_openvox_agent_dmg_on
      end
    end

    context 'with an x86_64 host' do
      let(:platform) { 'osx-26-x86_64' }

      it 'compares versions by number' do
        expect(host).to receive(:generic_install_dmg).with("#{url}openvox-agent-9.10.0-1.macos.all.x86_64.dmg",
                                                           'openvox-agent-9.10.0', 'openvox-agent-9.10.0-1-installer.pkg')

        install_openvox_agent_dmg_on
      end
    end

    context 'when the collection has no DMG for the architecture' do
      let(:platform) { 'osx-15-arm64' }
      let(:files) { %w[openvox-agent-9.9.0-1.macos.all.x86_64.dmg] }

      it 'raises' do
        expect { install_openvox_agent_dmg_on }.to raise_error(RuntimeError, "No openvox-agent DMG for arm64 found at #{url}")
      end
    end
  end
end
