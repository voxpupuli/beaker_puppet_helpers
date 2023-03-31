# frozen_string_literal: true

require 'spec_helper'

class ClassMixedWithDSLHelpers
  include Beaker::DSL::Patterns
  include BeakerPuppetHelpers::DSL

  def logger
    @logger ||= RSpec::Mocks::Double.new('Beaker::Logger').as_null_object
  end
end

describe ClassMixedWithDSLHelpers do
  let(:master) { double('Beaker::Host') }
  let(:agent)  { double('Beaker::Host') }
  let(:hosts)  { [master, agent] }

  describe '#apply_manifest_on' do
    before do
      hosts.each do |host|
        allow(host).to receive(:tmpfile).and_return('temp')
        allow(host).to receive(:rm_rf).with('temp')
        allow(host).to receive(:[]).with(:default_apply_opts)
      end
    end

    it 'calls puppet' do
      expect(subject).to receive(:create_remote_file).and_return(true)
      expect(Beaker::PuppetCommand).to receive(:new).and_return('puppet_command')
      expect(subject).to receive(:on).with(agent, 'puppet_command', acceptable_exit_codes: [0])

      subject.apply_manifest_on(agent, 'class { "boo": }')
    end

    it 'operates on an array of hosts' do
      the_hosts = [master, agent]

      expect(subject).to receive(:create_remote_file).twice.and_return(true)
      the_hosts.each do |host|
        expect(Beaker::PuppetCommand).to receive(:new).and_return('puppet_command')
        expect(subject).to receive(:on).with(host, 'puppet_command', acceptable_exit_codes: [0])
      end

      result = subject.apply_manifest_on(the_hosts, 'include foobar')
      expect(result).to be_an(Array)
    end

    it 'operates on an array of hosts' do
      InParallel::InParallelExecutor.logger = subject.logger
      # This will only get hit if forking processes is supported and at least 2 items are being submitted to run in parallel
      # expect( InParallel::InParallelExecutor ).to receive(:_execute_in_parallel).with(any_args).and_call_original.exactly(2).times
      the_hosts = [master, agent]

      allow(subject).to receive(:create_remote_file).and_return(true)
      allow(Beaker::PuppetCommand).to receive(:new).and_return('puppet_command')
      the_hosts.each do |host|
        allow(subject).to receive(:on).with(host, 'puppet_command', acceptable_exit_codes: [0])
      end

      result = subject.apply_manifest_on(the_hosts, 'include foobar')
      expect(result).to be_an(Array)
    end

    it 'runs block_on in parallel if set' do
      InParallel::InParallelExecutor.logger = subject.logger
      the_hosts = [master, agent]

      allow(subject).to receive(:create_remote_file).and_return(true)
      allow(Beaker::PuppetCommand).to receive(:new).and_return('puppet_command')
      the_hosts.each do |host|
        allow(subject).to receive(:on).with(host, 'puppet_command', acceptable_exit_codes: [0])
      end
      expect(subject).to receive(:block_on).with(anything, run_in_parallel: true)

      subject.apply_manifest_on(the_hosts, 'include foobar', { run_in_parallel: true })
    end

    it 'adds acceptable exit codes with :catch_failures' do
      expect(subject).to receive(:create_remote_file).and_return(true)
      expect(Beaker::PuppetCommand).to receive(:new).and_return('puppet_command')
      expect(subject).to receive(:on).with(agent, 'puppet_command', acceptable_exit_codes: [0, 2])

      subject.apply_manifest_on(agent, 'class { "boo": }', catch_failures: true)
    end

    it 'allows acceptable exit codes through :catch_failures' do
      expect(subject).to receive(:create_remote_file).and_return(true)
      expect(Beaker::PuppetCommand).to receive(:new).and_return('puppet_command')
      expect(subject).to receive(:on).with(agent, 'puppet_command', acceptable_exit_codes: [4, 0, 2])

      subject.apply_manifest_on(agent, 'class { "boo": }', acceptable_exit_codes: [4], catch_failures: true)
    end

    it 'enforces a 0 exit code through :catch_changes' do
      expect(subject).to receive(:create_remote_file).and_return(true)
      expect(Beaker::PuppetCommand).to receive(:new).and_return('puppet_command')
      expect(subject).to receive(:on).with(agent, 'puppet_command', acceptable_exit_codes: [0])

      subject.apply_manifest_on(agent, 'class { "boo": }', catch_changes: true)
    end

    it 'enforces a 2 exit code through :expect_changes' do
      expect(subject).to receive(:create_remote_file).and_return(true)
      expect(Beaker::PuppetCommand).to receive(:new).and_return('puppet_command')
      expect(subject).to receive(:on).with(agent, 'puppet_command', acceptable_exit_codes: [2])

      subject.apply_manifest_on(
        agent,
        'class { "boo": }',
        expect_changes: true,
      )
    end

    it 'enforces exit codes through :expect_failures' do
      expect(subject).to receive(:create_remote_file).and_return(true)
      expect(Beaker::PuppetCommand).to receive(:new).and_return('puppet_command')
      expect(subject).to receive(:on).with(agent, 'puppet_command', acceptable_exit_codes: [1, 4, 6])

      subject.apply_manifest_on(agent, 'class { "boo": }', expect_failures: true)
    end

    it 'enforces exit codes through :expect_failures' do
      expect do
        subject.apply_manifest_on(agent, 'class { "boo": }', expect_failures: true, catch_failures: true)
      end.to raise_error(ArgumentError, /catch_failures.+expect_failures/)
    end

    it 'enforces added exit codes through :expect_failures' do
      expect(subject).to receive(:create_remote_file).and_return(true)
      expect(Beaker::PuppetCommand).to receive(:new).and_return('puppet_command')

      expect(subject).to receive(:on).with(agent, 'puppet_command', acceptable_exit_codes: [1, 2, 3, 4, 5, 6])

      subject.apply_manifest_on(agent, 'class { "boo": }', acceptable_exit_codes: (1..5), expect_failures: true)
    end

    it 'can set the --parser future flag' do
      expect(subject).to receive(:create_remote_file).and_return(true)

      expect(Beaker::PuppetCommand).to receive(:new).with('apply', anything, include(parser: 'future')).and_return('puppet_command')

      expect(subject).to receive(:on).with(agent, 'puppet_command', acceptable_exit_codes: [0])

      subject.apply_manifest_on(agent, 'class { "boo": }', future_parser: true)
    end

    it 'can set the --noops flag' do
      expect(subject).to receive(:create_remote_file).and_return(true)
      expect(Beaker::PuppetCommand).to receive(:new).with('apply', anything, include(noop: nil)).and_return('puppet_command')
      expect(subject).to receive(:on).with(agent, 'puppet_command', acceptable_exit_codes: [0])

      subject.apply_manifest_on(agent, 'class { "boo": }', noop: true)
    end

    it 'can set the --debug flag' do
      allow(subject).to receive(:hosts).and_return(hosts)
      allow(subject).to receive(:create_remote_file).and_return(true)
      allow(subject).to receive(:on).with(agent, 'puppet_command', acceptable_exit_codes: [0])

      expect(Beaker::PuppetCommand).to receive(:new).with(
        'apply', anything, include(debug: nil)
      ).and_return('puppet_command')

      subject.apply_manifest_on(agent, 'class { "boo": }', debug: true)
    end
  end

  describe '#apply_manifest' do
    it 'delegates to #apply_manifest_on with the default host' do
      expect(subject).to receive(:default).and_return(agent)
      expect(subject).to receive(:apply_manifest_on).with(agent, 'manifest', { opt: 'value' }).once

      subject.apply_manifest('manifest', { opt: 'value' })
    end
  end

  describe '#fact_on' do
    it 'retrieves a fact on a single host' do
      result = double('Beaker::Result', stdout: '{"osfamily": "family"}')
      expect(subject).to receive(:on).and_return(result)

      expect(subject.fact_on('host', 'osfamily')).to eq('family')
    end

    it 'converts each element to a structured fact when it receives an array of results from #on' do
      times = hosts.length

      result = double('Beaker::Result', stdout: '{"os": {"name":"name", "family": "family"}}')
      allow(subject).to receive(:on).and_return([result] * times)

      expect(subject.fact_on(hosts, 'os')).to eq([{ 'name' => 'name', 'family' => 'family' }] * times)
    end

    it 'returns a single result for single host' do
      result = double('Beaker::Result', stdout: '{"osfamily": "family"}')
      allow(subject).to receive(:on).and_return(result)

      expect(subject.fact_on('host', 'osfamily')).to eq('family')
    end

    it 'preserves data types' do
      result = double('Beaker::Result', stdout: '{"identity": { "uid": 0, "user": "root", "privileged": true }}')
      allow(subject).to receive(:on).and_return(result)

      structured_fact = subject.fact_on('host', 'identity')

      expect(structured_fact['uid'].class).to be(Integer)
      expect(structured_fact['user'].class).to be(String)
      expect(structured_fact['privileged'].class).to be(TrueClass)
    end

    it 'raises an error when it receives a symbol for a fact' do
      expect { subject.fact_on('host', :osfamily) }
        .to raise_error(ArgumentError, /fact_on's `name` option must be a String. You provided a Symbol: 'osfamily'/)
    end
  end

  describe '#fact' do
    it 'delegates to #fact_on with the default host' do
      expect(subject).to receive(:fact_on).with(anything, 'osfamily', {}).once
      expect(subject).to receive(:default)

      subject.fact('osfamily')
    end
  end
end
