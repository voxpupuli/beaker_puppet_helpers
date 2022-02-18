# frozen_string_literal: true

require 'spec_helper'

describe BeakerPuppetHelpers::InstallUtils do
  describe '.install_puppet_release_repo_on' do
    let(:host) { double('Beaker::Host') }
    let(:packaging_platform) { Beaker::Platform.new(platform) }

    before { allow(host).to receive(:[]).with('packaging_platform').and_return(packaging_platform) }

    context 'default options' do
      subject { described_class.install_puppet_release_repo_on(host) }

      context 'on EL 7' do
        let(:platform) { 'el-7-x86_64' }

        it 'installs from the correct url' do
          expect(host).to receive(:install_package).with('https://yum.puppet.com/puppet-release-el-7.noarch.rpm')

          subject
        end
      end

      context 'on Fedora 34' do
        let(:platform) { 'fedora-34-x86_64' }

        it 'installs from the correct url' do
          expect(host).to receive(:install_package).with('https://yum.puppet.com/puppet-release-fedora-34.noarch.rpm')

          subject
        end
      end

      context 'on SLES 15' do
        let(:platform) { 'sles-15-x86_64' }

        it 'installs from the correct url and calls rpm --import' do
          expect(host).to receive(:install_package).with('https://yum.puppet.com/puppet-release-sles-15.noarch.rpm')

          expect(described_class).to receive(:wget_on).with(host, 'https://yum.puppet.com/RPM-GPG-KEY-puppet').and_yield('puppet.gpg').once
          expect(Beaker::Command).to receive(:new).with("rpm --import 'puppet.gpg'").and_return("rpm --import 'puppet.gpg'").once
          expect(host).to receive(:exec).with("rpm --import 'puppet.gpg'").once

          expect(described_class).to receive(:wget_on).with(host, 'https://yum.puppet.com/RPM-GPG-KEY-puppet-20250406').and_yield('puppet-20250406.gpg').once
          expect(Beaker::Command).to receive(:new).with("rpm --import 'puppet-20250406.gpg'").and_return("rpm --import 'puppet-20250406.gpg'").once
          expect(host).to receive(:exec).with("rpm --import 'puppet-20250406.gpg'").once

          subject
        end
      end

      context 'on Debian 11' do
        let(:platform) { 'debian-11-x86_64' }
        before { allow(host).to receive(:[]).with('platform').and_return(packaging_platform) }

        it 'installs from the correct url and runs apt-get update' do
          expect(described_class).to receive(:wget_on).with(host, 'https://apt.puppet.com/puppet-release-bullseye.deb').and_yield('filename.deb')
          expect(host).to receive(:install_package).with('filename.deb')
          expect(Beaker::Command).to receive(:new).with('apt-get update').and_return('apt-get update')
          expect(host).to receive(:exec).with('apt-get update')
          expect(host).to receive(:add_env_var).with('PATH', '/opt/puppetlabs/bin')

          subject
        end
      end
    end
  end

  describe '.wget_on' do
    let(:host) { double('Beaker::Host') }
    let(:url) { 'https://apt.puppet.com/puppet-release-bullseye.deb' }

    it do
      expect(Beaker::Command).to receive(:new).with("mktemp -t 'puppet-release-bullseye-XXXXXX.deb'").and_return('MKTEMP')
      result = Beaker::Result.new(host, 'MKTEMP')
      result.stdout = "/tmp/puppet-release-bullseye-ABCDEF.deb\n"
      expect(host).to receive(:exec).with('MKTEMP').and_return(result)

      expect(Beaker::Command).to receive(:new).with("wget -O '/tmp/puppet-release-bullseye-ABCDEF.deb' 'https://apt.puppet.com/puppet-release-bullseye.deb'").and_return('WGET')
      expect(host).to receive(:exec).with('WGET')

      expect(host).to receive(:rm_rf).with('/tmp/puppet-release-bullseye-ABCDEF.deb')

      expect { |b| described_class.wget_on(host, url, &b) }.to yield_with_args('/tmp/puppet-release-bullseye-ABCDEF.deb')
    end
  end
end
