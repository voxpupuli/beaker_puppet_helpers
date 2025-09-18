# frozen_string_literal: true

# rubocop:disable RSpec/MultipleMemoizedHelpers
require 'spec_helper'

class ClassMixedWithDSLInstallUtils
  include Beaker::DSL::Patterns
  include BeakerPuppetHelpers::WindowsUtils

  def logger
    @logger ||= RSpec::Mocks::Double.new('Beaker::Logger').as_null_object
  end
end

describe BeakerPuppetHelpers::WindowsUtils do
  subject(:dsl) { ClassMixedWithDSLInstallUtils.new }

  let(:windows_temp) { 'C:\\Windows\\Temp' }
  let(:batch_path) { '/fake/batch/path' }
  let(:msi_path)            { 'c:\\foo\\puppet.msi' }
  let(:winhost)             do
    make_host('winhost',
              { platform: Beaker::Platform.new('windows-2008r2-64'),
                pe_ver: '3.0',
                working_dir: '/tmp',
                is_cygwin: true, })
  end
  let(:winhost_non_cygwin) do
    make_host('winhost_non_cygwin',
              { platform: 'windows',
                pe_ver: '3.0',
                working_dir: '/tmp',
                is_cygwin: 'false', })
  end
  let(:hosts) { [winhost, winhost_non_cygwin] }

  def expect_install_called
    result = Beaker::Result.new(nil, 'temp')
    result.exit_code = 0

    hosts.each do |host|
      expectation = expect(subject).to receive(:on).with(host, having_attributes(command: "\"#{batch_path}\""),
                                                         anything).and_return(result)
      if block_given?
        should_break = yield expectation
        break if should_break
      end
    end
  end

  def expect_status_called(start_type = 'DEMAND_START')
    result = Beaker::Result.new(nil, 'temp')
    result.exit_code = 0
    result.stdout = case start_type
                    when 'DISABLED'
                      '        START_TYPE         : 4   DISABLED'
                    when 'AUTOMATIC'
                      '        START_TYPE         : 2   AUTO_START'
                    else # 'DEMAND_START'
                      '        START_TYPE         : 3   DEMAND_START'
                    end

    hosts.each do |host|
      expect(subject).to receive(:on).with(host,
                                           having_attributes(command: 'sc qc puppet || sc qc pe-puppet')).and_yield(result)
    end
  end

  def expect_version_log_called(_times = hosts.length)
    path = "'%PROGRAMFILES%\\Puppet Labs\\puppet\\misc\\versions.txt'"

    result = Beaker::Result.new(nil, 'temp')
    result.exit_code = 0

    hosts.each do |host|
      expect(subject).to receive(:on).with(host, "cmd /c type #{path}", anything).and_return(result)
    end
  end

  def expect_reg_query_called(_times = hosts.length)
    expect(hosts).to all(receive(:is_x86_64?).and_return(true))

    hosts.each do |host|
      expect(subject).to receive(:on)
        .with(host, having_attributes(command: /reg query "HKLM\\SOFTWARE\\Wow6432Node\\Puppet Labs\\PuppetInstaller/))
    end
  end

  def expect_puppet_path_called
    hosts.each do |host|
      next if host.is_cygwin?

      result = Beaker::Result.new(nil, 'temp')
      result.exit_code = 0

      expect(subject).to receive(:on)
        .with(host, having_attributes(command: 'puppet -h'), anything)
        .and_return(result)
    end
  end

  describe '#get_agent_package_url' do
    let(:base_package_repo_html) do
      <<-HTML
        <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">
        <html>
          <head>
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
            <title>Index of /windows/</title>
          </head>
          <body>
            <h1>Index of /windows/</h1>
            <hr>
              <pre>
                <a href="../">../</a>
                <a href="openvox7/">openvox7/</a>
                <a href="openvox8/">openvox8/</a>
              </pre>
            <hr>
          </body>
        </html>
      HTML
    end
    let(:package_repo_html) do
      <<-HTML
        <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">
        <html>
          <head>
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
            <title>Index of /windows/openvox8/</title>
          </head>
          <body>
            <h1>Index of /windows/openvox8/</h1>
            <hr>
              <pre>
                <a href="../">../</a>
                <a href="unsigned/">unsigned/</a>
                <a href="openvox-agent-8.19.2-x64.msi">openvox-agent-8.19.2-x64.msi</a>
                <a href="openvox-agent-8.21.2-rc1-x64.msi">openvox-agent-8.21.2-rc1-x64.msi</a>
                <a href="openvox-agent-8.22.0-x64.msi">openvox-agent-8.22.0-x64.msi</a>
                <a href="openvox-agent-8.22.1-x64.msi">openvox-agent-8.22.1-x64.msi</a>
                <a href="openvox-agent-8.23.0-x64.msi">openvox-agent-8.23.0-x64.msi</a>
                <a href="openvox-agent-8.23.1-x64.msi">openvox-agent-8.23.1-x64.msi</a>
              </pre>
            <hr>
          </body>
        </html>
      HTML
    end

    before do
      # Stub Net::HTTP.get_response for base url and final url
      allow(Net::HTTP).to receive(:get_response) do |uri|
        case uri.to_s
        when 'https://downloads.voxpupuli.org/windows/'
          instance_double(Net::HTTPOK, is_a?: true, body: base_package_repo_html)
        when 'https://downloads.voxpupuli.org/windows/openvox8/'
          instance_double(Net::HTTPOK, is_a?: true, body: package_repo_html)
        else
          raise "Unexpected URL: #{uri}"
        end
      end
    end

    it 'returns the latest MSI URL for the openvox collection' do
      result = dsl.get_agent_package_url('openvox')
      expect(result).to eq('https://downloads.voxpupuli.org/windows/openvox8/openvox-agent-8.23.1-x64.msi')
    end

    it 'returns the latest MSI URL for the openvox8 collection' do
      result = dsl.get_agent_package_url('openvox8')
      expect(result).to eq('https://downloads.voxpupuli.org/windows/openvox8/openvox-agent-8.23.1-x64.msi')
    end

    it 'raises for unsupported collection prefix' do
      expect { dsl.get_agent_package_url('foo') }.to raise_error('Unsupported collection: foo')
    end

    it 'raises when no MSI files found' do
      empty_html = '<html><body></body></html>'
      allow(Net::HTTP).to receive(:get_response).and_return(
        instance_double(Net::HTTPOK, is_a?: true, body: empty_html),
      )
      expect { dsl.get_agent_package_url('openvox8') }.to raise_error(SystemExit)
    end
  end

  describe '#install_msi_on' do
    let(:log_file) { '/fake/log/file.log' }

    before do
      result = Beaker::Result.new(nil, 'temp')
      result.exit_code = 0

      hosts.each do |host|
        allow(dsl).to receive(:on)
          .with(host, having_attributes(command: "\"#{batch_path}\""))
          .and_return(result)
      end

      allow(dsl).to receive(:create_install_msi_batch_on).and_return([batch_path, log_file])
    end

    it 'specifies a PUPPET_AGENT_STARTUP_MODE of Manual by default' do
      expect_install_called
      expect_puppet_path_called
      expect_status_called
      expect_reg_query_called
      expect_version_log_called
      expect(dsl).to receive(:create_install_msi_batch_on).with(anything, anything, { 'PUPPET_AGENT_STARTUP_MODE' => 'Manual' })
      dsl.install_msi_on(hosts, msi_path, msi_opts: {})
    end

    it 'allows configuration of PUPPET_AGENT_STARTUP_MODE to Automatic' do
      expect_install_called
      expect_puppet_path_called
      expect_status_called('AUTOMATIC')
      expect_reg_query_called
      expect_version_log_called
      value = 'Automatic'
      expect(dsl).to receive(:create_install_msi_batch_on).with(anything, anything, { 'PUPPET_AGENT_STARTUP_MODE' => value })
      dsl.install_msi_on(hosts, msi_path, msi_opts: { 'PUPPET_AGENT_STARTUP_MODE' => value })
    end

    it 'allows configuration of PUPPET_AGENT_STARTUP_MODE to Disabled' do
      expect_install_called
      expect_puppet_path_called
      expect_status_called('DISABLED')
      expect_reg_query_called
      expect_version_log_called
      value = 'Disabled'
      expect(dsl).to receive(:create_install_msi_batch_on).with(anything, anything, { 'PUPPET_AGENT_STARTUP_MODE' => value })
      dsl.install_msi_on(hosts, msi_path, msi_opts: { 'PUPPET_AGENT_STARTUP_MODE' => value })
    end

    it 'does not generate a command to emit a log file without the :debug option set' do
      expect_install_called
      expect_puppet_path_called
      expect_status_called
      expect_reg_query_called
      expect_version_log_called

      expect(dsl).not_to receive(:file_contents_on).with(anything, log_file)

      dsl.install_msi_on(hosts, msi_path)
    end

    it 'generates a command to emit a log file when the install script fails' do
      # NOTE: a single failure aborts executing against remaining hosts
      expect_install_called do |e|
        e.and_raise
        true # break
      end

      expect(dsl).to receive(:file_contents_on).with(anything, log_file)
      expect do
        dsl.install_msi_on(hosts, msi_path)
      end.to raise_error(RuntimeError)
    end

    it 'generates a command to emit a log file with the :debug option set' do
      expect_install_called
      expect_reg_query_called
      expect_puppet_path_called
      expect_status_called
      expect_version_log_called

      expect(dsl).to receive(:file_contents_on).with(anything, log_file).exactly(hosts.length).times

      dsl.install_msi_on(hosts, msi_path, msi_opts: {}, opts: { debug: true })
    end

    it 'passes msi_path to #create_install_msi_batch_on as-is' do
      expect_install_called
      expect_reg_query_called
      expect_puppet_path_called
      expect_status_called
      expect_version_log_called
      test_path = 'test/path'
      expect(dsl).to receive(:create_install_msi_batch_on).with(anything, test_path, anything)
      dsl.install_msi_on(hosts, test_path)
    end

    it 'searches in Wow6432Node for the remembered startup setting on 64-bit hosts' do
      expect_install_called
      expect_puppet_path_called
      expect_status_called
      expect_version_log_called

      hosts.each do |host|
        expect(host).to receive(:is_x86_64?).and_return(true)

        expect(dsl).to receive(:on).with(host, having_attributes(command: 'reg query "HKLM\\SOFTWARE\\Wow6432Node\\Puppet Labs\\PuppetInstaller" /v "RememberedPuppetAgentStartupMode" | findstr Manual'))
      end

      dsl.install_msi_on(hosts, msi_path, msi_opts: { 'PUPPET_AGENT_STARTUP_MODE' => 'Manual' })
    end

    it 'omits Wow6432Node in the registry search for remembered startup setting on 32-bit hosts' do
      expect_install_called
      expect_puppet_path_called
      expect_status_called
      expect_version_log_called

      hosts.each do |host|
        expect(host).to receive(:is_x86_64?).and_return(false)

        expect(dsl).to receive(:on).with(host, having_attributes(command: 'reg query "HKLM\\SOFTWARE\\Puppet Labs\\PuppetInstaller" /v "RememberedPuppetAgentStartupMode" | findstr Manual'))
      end

      dsl.install_msi_on(hosts, msi_path, msi_opts: { 'PUPPET_AGENT_STARTUP_MODE' => 'Manual' })
    end
  end

  describe '#create_install_msi_batch_on' do
    let(:tmp) { '/tmp/create_install_msi_batch_on' }
    let(:tmp_slashes) { tmp.tr('/', '\\') }

    before do
      FakeFS::FileSystem.add(File.expand_path(tmp))
      hosts.each do |host|
        allow(host).to receive(:system_temp_path).and_return(tmp)
      end
    end

    it 'passes msi_path & msi_opts down to #msi_install_script' do
      allow(winhost).to receive(:do_scp_to)
      test_path = '/path/to/test/with/13540'
      test_opts = { 'key1' => 'val1', 'key2' => 'val2' }
      expect(dsl).to receive(:msi_install_script).with(
        test_path, test_opts, anything
      )
      dsl.create_install_msi_batch_on(winhost, test_path, test_opts)
    end

    it 'SCPs to & returns the same batch file path, corrected for slashes' do
      test_time = Time.now
      allow(Time).to receive(:new).and_return(test_time)
      timestamp = test_time.strftime('%Y-%m-%d_%H.%M.%S')

      correct_path = "#{tmp_slashes}\\install-puppet-msi-#{timestamp}.bat"
      expect(winhost).to receive(:do_scp_to).with(anything, correct_path, {})
      test_path, = dsl.create_install_msi_batch_on(winhost, msi_path, {})
      expect(test_path).to eq(correct_path)
    end

    it 'returns & sends log_path to #msi_install_scripts, corrected for slashes' do
      allow(winhost).to receive(:do_scp_to)
      test_time = Time.now
      allow(Time).to receive(:new).and_return(test_time)
      timestamp = test_time.strftime('%Y-%m-%d_%H.%M.%S')

      correct_path = "#{tmp_slashes}\\install-puppet-#{timestamp}.log"
      expect(dsl).to receive(:msi_install_script).with(anything, anything, correct_path)
      _, log_path = dsl.create_install_msi_batch_on(winhost, msi_path, {})
      expect(log_path).to eq(correct_path)
    end
  end

  describe '#msi_install_script' do
    let(:log_path) { '/log/msi_install_script' }

    context 'with msi_params parameter' do
      it 'can take an empty hash' do
        expected_cmd = %r{^start /w msiexec\.exe /i ".*" /qn /L\*V #{log_path}\ .exit}m
        expect(dsl.msi_install_script(msi_path, {}, log_path)).to match(expected_cmd)
      end

      it 'uses a key-value pair correctly' do
        params = { 'tk1' => 'tv1' }
        expected_cmd = %r{^start /w msiexec\.exe /i ".*" /qn /L\*V #{log_path}\ tk1=tv1}
        expect(dsl.msi_install_script(msi_path, params, log_path)).to match(expected_cmd)
      end

      it 'uses multiple key-value pairs correctly' do
        params = { 'tk1' => 'tv1', 'tk2' => 'tv2' }
        expected_cmd = %r{^start /w msiexec\.exe /i ".*" /qn /L\*V #{log_path}\ tk1=tv1\ tk2=tv2}
        expect(dsl.msi_install_script(msi_path, params, log_path)).to match(expected_cmd)
      end
    end

    context 'with msi_path parameter' do
      it 'generates an appropriate command with a MSI file path using non-Windows slashes' do
        msi_path = 'c:/foo/puppet.msi'
        expected_cmd = %r{^start /w msiexec\.exe /i "c:\\foo\\puppet.msi" /qn /L\*V #{log_path}}
        expect(dsl.msi_install_script(msi_path, {}, log_path)).to match(expected_cmd)
      end

      it 'generates an appropriate command with a MSI http(s) url' do
        msi_url = 'https://downloads.puppetlabs.com/puppet.msi'
        expected_cmd = %r{^start /w msiexec\.exe /i "https://downloads\.puppetlabs\.com/puppet\.msi" /qn /L\*V #{log_path}}
        expect(dsl.msi_install_script(msi_url, {}, log_path)).to match(expected_cmd)
      end

      it 'generates an appropriate command with a MSI file url' do
        msi_url = 'file://c:\\foo\\puppet.msi'
        expected_cmd = %r{^start /w msiexec\.exe /i "file://c:\\foo\\puppet\.msi" /qn /L\*V #{log_path}}
        expect(dsl.msi_install_script(msi_url, {}, log_path)).to match(expected_cmd)
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
