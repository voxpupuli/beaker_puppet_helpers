# frozen_string_literal: true

module BeakerPuppetHelpers
  # The DSL methods for beaker. These are included in Beaker.
  module DSL
    # @!macro [new] common_opts
    #   @param [Hash{Symbol=>String}] opts Options to alter execution.
    #   @option opts [Boolean] :silent (false) Do not produce log output
    #   @option opts [Array<Fixnum>] :acceptable_exit_codes ([0]) An array
    #     (or range) of integer exit codes that should be considered
    #     acceptable.  An error will be thrown if the exit code does not
    #     match one of the values in this list.
    #   @option opts [Boolean] :accept_all_exit_codes (false) Consider all
    #     exit codes as passing.
    #   @option opts [Boolean] :dry_run (false) Do not actually execute any
    #     commands on the SUT
    #   @option opts [String] :stdin (nil) Input to be provided during command
    #     execution on the SUT.
    #   @option opts [Boolean] :pty (false) Execute this command in a pseudoterminal.
    #   @option opts [Boolean] :expect_connection_failure (false) Expect this command
    #     to result in a connection failure, reconnect and continue execution.
    #   @option opts [Hash{String=>String}] :environment ({}) These will be
    #     treated as extra environment variables that should be set before
    #     running the command.
    #

    # Runs 'puppet apply' on a remote host, piping manifest through stdin
    #
    # @param [Beaker::Host] hosts
    #   The host that this command should be run on
    #
    # @param [String] manifest The puppet manifest to apply
    #
    # @!macro common_opts
    # @option opts [Boolean]  :parseonly (false) If this key is true, the
    #                          "--parseonly" command line parameter will
    #                          be passed to the 'puppet apply' command.
    #
    # @option opts [Boolean]  :trace (false) If this key exists in the Hash,
    #                         the "--trace" command line parameter will be
    #                         passed to the 'puppet apply' command.
    #
    # @option opts [Array<Integer>] :acceptable_exit_codes ([0]) The list of exit
    #                          codes that will NOT raise an error when found upon
    #                          command completion.  If provided, these values will
    #                          be combined with those used in :catch_failures and
    #                          :expect_failures to create the full list of
    #                          passing exit codes.
    #
    # @option opts [Hash]     :environment Additional environment variables to be
    #                         passed to the 'puppet apply' command
    #
    # @option opts [Boolean]  :catch_failures (false) By default `puppet
    #                         --apply` will exit with 0, which does not count
    #                         as a test failure, even if there were errors or
    #                         changes when applying the manifest. This option
    #                         enables detailed exit codes and causes a test
    #                         failure if `puppet --apply` indicates there was
    #                         a failure during its execution.
    #
    # @option opts [Boolean]  :catch_changes (false) This option enables
    #                         detailed exit codes and causes a test failure
    #                         if `puppet --apply` indicates that there were
    #                         changes or failures during its execution.
    #
    # @option opts [Boolean]  :expect_changes (false) This option enables
    #                         detailed exit codes and causes a test failure
    #                         if `puppet --apply` indicates that there were
    #                         no resource changes during its execution.
    #
    # @option opts [Boolean]  :expect_failures (false) This option enables
    #                         detailed exit codes and causes a test failure
    #                         if `puppet --apply` indicates there were no
    #                         failure during its execution.
    #
    # @option opts [Boolean]  :future_parser (false) This option enables
    #                         the future parser option that is available
    #                         from Puppet verion 3.2
    #                         By default it will use the 'current' parser.
    #
    # @option opts [Boolean]  :noop (false) If this option exists, the
    #                         the "--noop" command line parameter will be
    #                         passed to the 'puppet apply' command.
    #
    # @option opts [String]   :modulepath The search path for modules, as
    #                         a list of directories separated by the system
    #                         path separator character. (The POSIX path separator
    #                         is ‘:’, and the Windows path separator is ‘;’.)
    #
    # @option opts [String]   :hiera_config The path of the hiera.yaml configuration.
    #
    # @option opts [Boolean]  :debug (false) If this option exists,
    #                         the "--debug" command line parameter
    #                         will be passed to the 'puppet apply' command.
    #
    # @option opts [Boolean]  :run_in_parallel Whether to run on each host in parallel.
    #
    # @option opts [Boolean]  :show_diff (false) If this option exists,
    #                         the "--show_diff=true" command line parameter
    #                         will be passed to the 'puppet apply' command.
    #
    # @param [Block] block This method will yield to a block of code passed
    #                      by the caller; this can be used for additional
    #                      validation, etc.
    #
    # @return [Array<Result>, Result, nil] An array of results, a result
    #   object, or nil. Check {Beaker::Shared::HostManager#run_block_on} for
    #   more details on this.
    def apply_manifest_on(hosts, manifest, opts = {}, &block)
      block_on hosts, opts do |host|
        on_options = {}
        on_options[:acceptable_exit_codes] = Array(opts[:acceptable_exit_codes])

        puppet_apply_opts = {}
        if opts[:debug]
          puppet_apply_opts[:debug] = nil
        else
          puppet_apply_opts[:verbose] = nil
        end
        puppet_apply_opts[:parseonly] = nil if opts[:parseonly]
        puppet_apply_opts[:trace] = nil if opts[:trace]
        puppet_apply_opts[:parser] = 'future' if opts[:future_parser]
        puppet_apply_opts[:modulepath] = opts[:modulepath] if opts[:modulepath]
        puppet_apply_opts[:hiera_config] = opts[:hiera_config] if opts[:hiera_config]
        puppet_apply_opts[:noop] = nil if opts[:noop]
        puppet_apply_opts[:show_diff] = nil if opts[:show_diff]

        # From puppet help:
        # "... an exit code of '2' means there were changes, an exit code of
        # '4' means there were failures during the transaction, and an exit
        # code of '6' means there were both changes and failures."
        if [opts[:catch_changes], opts[:catch_failures], opts[:expect_failures], opts[:expect_changes]].compact.length > 1
          raise(ArgumentError,
                'Cannot specify more than one of `catch_failures`, ' \
                '`catch_changes`, `expect_failures`, or `expect_changes` ' \
                'for a single manifest')
        end

        if opts[:catch_changes]
          puppet_apply_opts['detailed-exitcodes'] = nil

          # We're after idempotency so allow exit code 0 only.
          on_options[:acceptable_exit_codes] |= [0]
        elsif opts[:catch_failures]
          puppet_apply_opts['detailed-exitcodes'] = nil

          # We're after only complete success so allow exit codes 0 and 2 only.
          on_options[:acceptable_exit_codes] |= [0, 2]
        elsif opts[:expect_failures]
          puppet_apply_opts['detailed-exitcodes'] = nil

          # We're after failures specifically so allow exit codes 1, 4, and 6 only.
          on_options[:acceptable_exit_codes] |= [1, 4, 6]
        elsif opts[:expect_changes]
          puppet_apply_opts['detailed-exitcodes'] = nil

          # We're after changes specifically so allow exit code 2 only.
          on_options[:acceptable_exit_codes] |= [2]
        else
          # Either use the provided acceptable_exit_codes or default to [0]
          on_options[:acceptable_exit_codes] |= [0]
        end

        # Not really thrilled with this implementation, might want to improve it
        # later. Basically, there is a magic trick in the constructor of
        # PuppetCommand which allows you to pass in a Hash for the last value in
        # the *args Array; if you do so, it will be treated specially. So, here
        # we check to see if our caller passed us a hash of environment variables
        # that they want to set for the puppet command. If so, we set the final
        # value of *args to a new hash with just one entry (the value of which
        # is our environment variables hash)
        puppet_apply_opts['ENV'] = opts[:environment] if opts.key?(:environment)

        puppet_apply_opts = host[:default_apply_opts].merge(puppet_apply_opts) if host[:default_apply_opts].respond_to? :merge

        file_path = host.tmpfile(%(apply_manifest_#{Time.now.strftime('%H%M%S%L')}), '.pp')
        begin
          create_remote_file(host, file_path, "#{manifest}\n")

          on(host, Beaker::PuppetCommand.new('apply', file_path, puppet_apply_opts), **on_options, &block)
        ensure
          host.rm_rf(file_path)
        end
      end
    end

    # Runs 'puppet apply' on default host
    # @see #apply_manifest_on
    # @return [Array<Result>, Result, nil] An array of results, a result
    #   object, or nil. Check {Beaker::Shared::HostManager#run_block_on} for
    #   more details on this.
    def apply_manifest(manifest, opts = {}, &block)
      apply_manifest_on(default, manifest, opts, &block)
    end

    # Get a facter fact from a provided host
    #
    # @param [Beaker::Host, Array<Beaker::Host>, String, Symbol] host
    #   One or more hosts to act upon, or a role (String or Symbol) that
    #   identifies one or more hosts.
    # @param [String] name The name of the fact to query for
    # @!macro common_opts
    # @return String The value of the fact 'name' on the provided host
    # @raise  [FailTest] Raises an exception if call to facter fails
    def fact_on(host, name, opts = {})
      raise(ArgumentError, "fact_on's `name` option must be a String. You provided a #{name.class}: '#{name}'") unless name.is_a?(String)

      if opts.is_a?(Hash)
        opts['json'] = nil
      else
        opts << ' --json'
      end

      result = on host, Beaker::Command.new('facter', [name], opts)
      if result.is_a?(Array)
        result.map { |res| JSON.parse(res.stdout)[name] }
      else
        JSON.parse(result.stdout)[name]
      end
    end

    # Get a facter fact from the default host
    # @see #fact_on
    def fact(name, opts = {})
      fact_on(default, name, opts)
    end

    # Show if bolt package is available
    #
    # @param [Beaker::Host] host
    # @return True if package is available.
    #
    def bolt_supported?(host = default)
      #
      # Supported platforms
      # https://github.com/puppetlabs/bolt/blob/main/documentation/bolt_installing.md
      # https://github.com/puppetlabs/bolt-vanagon/tree/main/configs/platforms

      case host['packaging_platform'].split('-', 3)[0, 1]
      when %w[el 7], %w[el 8], %w[el 9],
        %w[debian 10], %w[debian 11],
        ['ubuntu', '20.04'], ['ubuntu', '22.04'],
        %w[osx 11], %w[osx 12],
        %w[sles 12], %w[sles 15],
        %w[fedora 36],
        %w[windows 2012r2]
        true
      else
        false
      end
    end
  end
end
