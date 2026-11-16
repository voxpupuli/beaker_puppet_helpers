# frozen_string_literal: true

require 'spec_helper'

describe BeakerPuppetHelpers::InstallUtils do
  describe '.implementation_from_collection' do
    {
      'none' => 'puppet',
      'puppet' => 'puppet',
      'puppet8' => 'puppet',
      'openvox' => 'openvox',
      'openvox9' => 'openvox',
    }.each do |collection, implementation|
      it "returns #{implementation} for the #{collection} collection" do
        expect(described_class.implementation_from_collection(collection)).to eq(implementation)
      end
    end
  end

  describe '.package_name' do
    let(:host) { instance_double(Beaker::Host) }
    let(:packaging_platform) { Beaker::Platform.new(platform) }

    before { allow(host).to receive(:[]).with('packaging_platform').and_return(packaging_platform) }

    context 'with EL 9 platform' do
      let(:platform) { 'el-9-x86_64' }

      it 'returns openvox-agent for the openvox implementation' do
        expect(described_class.package_name(host, implementation: 'openvox')).to eq('openvox-agent')
      end

      it 'returns puppet-agent for the puppet implementation with prefer_aio true' do
        expect(described_class.package_name(host, prefer_aio: true, implementation: 'puppet')).to eq('puppet-agent')
      end

      it 'returns puppet for the puppet implementation with prefer_aio false' do
        expect(described_class.package_name(host, prefer_aio: false, implementation: 'puppet')).to eq('puppet')
      end

      it 'returns puppet for the none implementation with prefer_aio true' do
        expect(described_class.package_name(host, prefer_aio: true, implementation: 'none')).to eq('puppet')
      end

      it 'raises an error naming an unknown implementation' do
        expect { described_class.package_name(host, implementation: 'foo') }.to raise_error(StandardError, "Unknown requirement 'foo'")
      end
    end

    context 'with Debian 12 platform' do
      let(:platform) { 'debian-12-amd64' }

      it 'returns puppet-agent for the puppet implementation with prefer_aio false' do
        expect(described_class.package_name(host, prefer_aio: false, implementation: 'puppet')).to eq('puppet-agent')
      end
    end
  end

  describe '.collection2packagename' do
    let(:host) { instance_double(Beaker::Host) }
    let(:packaging_platform) { Beaker::Platform.new(platform) }

    before { allow(host).to receive(:[]).with('packaging_platform').and_return(packaging_platform) }

    context 'with Debian 11 platform' do
      let(:platform) { 'debian-11-amd64' }

      it 'returns openvox-agent for the openvox9 collection' do
        expect(described_class.collection2packagename(host, 'openvox9')).to eq('openvox-agent')
      end

      it 'returns the AIO package puppet-agent for the puppet8 collection' do
        expect(described_class.collection2packagename(host, 'puppet8')).to eq('puppet-agent')
      end

      it 'returns the distribution package puppet for the puppet8 collection with prefer_aio false' do
        expect(described_class.collection2packagename(host, 'puppet8', prefer_aio: false)).to eq('puppet')
      end

      it 'returns the distribution package puppet for the none collection' do
        expect(described_class.collection2packagename(host, 'none')).to eq('puppet')
      end
    end

    context 'with Debian 12 platform' do
      let(:platform) { 'debian-12-amd64' }

      it 'returns the distribution package puppet-agent for the none collection' do
        expect(described_class.collection2packagename(host, 'none')).to eq('puppet-agent')
      end
    end
  end

  describe '.puppet_package_name' do
    let(:host) { instance_double(Beaker::Host) }
    let(:packaging_platform) { Beaker::Platform.new(platform) }

    before { allow(host).to receive(:[]).with('packaging_platform').and_return(packaging_platform) }

    {
      'debian-11-amd64' => %w[puppet-agent puppet],
      'debian-12-amd64' => %w[puppet-agent puppet-agent],
      'el-9-x86_64' => %w[puppet-agent puppet],
      'fedora-44-x86_64' => %w[puppet-agent puppet],
      'sles-15-x86_64' => %w[puppet-agent puppet],
      'freebsd-14-amd64' => %w[sysutils/puppet8 sysutils/puppet8],
      'ubuntu-22.04-amd64' => %w[puppet-agent puppet],
      'archlinux-rolling-x64' => %w[puppet puppet],
    }.each do |platform_name, (aio_package, os_package)|
      context "with #{platform_name} platform" do
        let(:platform) { platform_name }

        it "returns #{aio_package} with prefer_aio true" do
          expect(described_class.puppet_package_name(host, prefer_aio: true)).to eq(aio_package)
        end

        it "returns #{os_package} with prefer_aio false" do
          expect(described_class.puppet_package_name(host, prefer_aio: false)).to eq(os_package)
        end
      end
    end
  end

  describe '.install_puppet_release_repo_on' do
    let(:host) { instance_double(Beaker::Host) }
    let(:packaging_platform) { Beaker::Platform.new(platform) }

    before { allow(host).to receive(:[]).with('packaging_platform').and_return(packaging_platform) }

    context 'with the openvox9 collection' do
      subject(:install_puppet_release_repo_on) { described_class.install_puppet_release_repo_on(host, 'openvox9') }

      context 'with EL 10 platform' do
        let(:platform) { 'el-10-x86_64' }

        it 'installs from the OpenVox yum url' do
          expect(host).to receive(:install_package).with('https://yum.voxpupuli.org/openvox9-release-el-10.noarch.rpm')

          install_puppet_release_repo_on
        end
      end

      {
        'debian-13-amd64' => 'openvox9-release-debian13.deb',
        'ubuntu-26.04-amd64' => 'openvox9-release-ubuntu26.04.deb',
      }.each do |platform_name, package_file|
        context "with #{platform_name} platform" do
          let(:platform) { platform_name }

          it "installs #{package_file}, runs apt-get update and adds /opt/puppetlabs/bin to PATH" do
            expect(described_class).to receive(:wget_on).with(host, "https://apt.voxpupuli.org/#{package_file}").and_yield('filename.deb')
            expect(host).to receive(:install_package).with('filename.deb')
            expect(Beaker::Command).to receive(:new).with('apt-get update').and_return('apt-get update')
            expect(host).to receive(:exec).with('apt-get update')
            expect(host).to receive(:add_env_var).with('PATH', '/opt/puppetlabs/bin')

            install_puppet_release_repo_on
          end
        end
      end

      context 'with Arch Linux platform' do
        let(:platform) { 'archlinux-rolling-x64' }

        it 'raises an error that the platform has no repository installation step' do
          expect { install_puppet_release_repo_on }.to raise_error(RuntimeError, 'No repository installation step for archlinux yet...')
        end
      end
    end

    context 'with the puppet8 collection' do
      subject(:install_puppet_release_repo_on) { described_class.install_puppet_release_repo_on(host, 'puppet8') }

      context 'with EL 9 platform' do
        let(:platform) { 'el-9-x86_64' }

        it 'installs from the Perforce yum url for the puppet8 collection' do
          expect(host).to receive(:install_package).with('https://yum.puppet.com/puppet8-release-el-9.noarch.rpm')

          install_puppet_release_repo_on
        end
      end
    end

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
end
