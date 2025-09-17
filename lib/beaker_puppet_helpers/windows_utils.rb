# frozen_string_literal: true

require 'net/http'
require 'nokogiri'
require 'open-uri'

module BeakerPuppetHelpers
  #
  # This module contains methods useful for Windows installs
  #
  module WindowsUtils
    # Given a host, returns it's system TEMP path
    #
    # @param [Host] host An object implementing {Beaker::Hosts}'s interface.
    #
    # @return [String] system temp path
    def get_system_temp_path(host)
      host.system_temp_path
    end
    alias get_temp_path get_system_temp_path

    # Given the puppet collection, returns the url of the newest msi available in the appropriate repo
    #
    # @param [String]
    #   The collection to install. The default (openvox) is the latest
    #   available version. Can also be openvox8, puppet8 and others.
    #
    # @return [String] url of the newest msi available in the package repo
    def get_agent_package_url(collection = 'openvox')
      windows_package_base_url =
        if collection.start_with?('puppet')
          'https://downloads.puppetlabs.com/windows/'
        elsif collection.start_with?('openvox')
          'https://downloads.voxpupuli.org/windows/'
        else
          raise "Unsupported collection: #{collection}"
        end
      # If the collection ends in a number, we can infer the package url directly
      if /\d+$/.match?(collection)
        windows_package_url = "#{windows_package_base_url}#{collection}/"
      else
        # Obtain the list of collections from the appropriate base url and pick the latest
        base_url = URI.parse(windows_package_base_url)
        base_response = Net::HTTP.get_response(base_url)
        raise "Failed to fetch URL: #{base_response.code} #{base_response.message}" unless base_response.is_a?(Net::HTTPSuccess)

        base_doc = Nokogiri::HTML(base_response.body)
        collection_dirs = base_doc.css('a').filter_map { |a| a['href'] }.grep(/^#{collection}\d+/)
        raise "No collections found at #{base_url} for colleciton #{collection}" if collection_dirs.empty?

        latest_collection = collection_dirs.max_by do |collection_version|
          # Grab the digits before the slash and convert to integer
          collection_version[/\d+/].to_i
        end
        windows_package_url = "#{windows_package_base_url}#{latest_collection}"
      end
      url = URI.parse(windows_package_url)
      response = Net::HTTP.get_response(url)

      # Fetch and parse the page
      raise "Failed to fetch URL: #{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess)

      doc = Nokogiri::HTML(response.body)

      # Create the regex for the agent package
      base_collection_name = collection.gsub(/\d+$/, '')
      agent_regex = /#{base_collection_name}-agent-(\d+\.\d+\.\d+)-.*\.msi$/i
      # Extract all hrefs that look like the appropriate MSI files
      files = doc.css('a').filter_map { |a| a['href'] }.grep(agent_regex)

      if files.empty?
        puts 'No MSI files found'
        exit 1
      end

      latest_msi = files.max_by do |file|
        version_str = file.match(agent_regex)[1]
        Gem::Version.new(version_str)
      end

      # Remove index.html if it exists in the windows_package_url
      windows_package_repo = windows_package_url.sub(/index\.html$/, '')
      # Return the full url to the latest msi
      "#{windows_package_repo}#{latest_msi}"
    end

    # Download the appropriate puppet version based on the collection to a specified file location
    #
    # @param [String]
    #   The collection to install. The default (openvox) is the latest
    #   available version. Can also be openvox8, puppet8 and others.
    #
    # @param [String] download_path The file location to write the downloaded msi to
    #
    # @return [String] The file location of the newly downloaded msi
    def download_agent_msi(collection = 'openvox', download_path = 'C:\Windows\Temp\puppet-agent.msi')
      # Get the url for the appropriate msi file
      msi_url = get_agent_package_url(collection)
      url = URI.parse(msi_url)
      Net::HTTP.start(url.host, url.port, use_ssl: url.scheme == 'https') do |http|
        resp = http.get(url.path)
        raise "Failed to download #{msi_url}: #{resp.code} #{resp.message}" unless resp.is_a?(Net::HTTPSuccess)

        File.binwrite(download_path, resp.body)
        download_path
      end
    end

    # Generates commands to be inserted into a Windows batch file to launch an MSI install
    # @param [String] msi_path The path of the MSI - can be a local Windows style file path like
    #                   C:\Windows\Temp\puppet-agent.msi OR a url like https://download.com/puppet.msi or file://C:\Windows\Temp\puppet-agent.msi
    # @param  [Hash{String=>String}] msi_opts MSI installer options
    #                   See https://docs.puppetlabs.com/guides/install_puppet/install_windows.html#msi-properties
    # @param [String] log_path The path to write the MSI log - must be a local Windows style file path
    #
    # @api private
    def msi_install_script(msi_path, msi_opts, log_path)
      # msiexec requires backslashes in file paths launched under cmd.exe start /w
      url_pattern = %r{^(https?|file)://}
      msi_path = msi_path.tr('/', '\\') unless msi_path&.match?(url_pattern)

      msi_params = msi_opts.map { |k, v| "#{k}=#{v}" }.join(' ')

      # msiexec requires quotes around paths with backslashes - c:\ or file://c:\
      # not strictly needed for http:// but it simplifies this code
      <<~BATCH
        start /w msiexec.exe /i "#{msi_path}" /qn /L*V #{log_path} #{msi_params}
        exit /B %errorlevel%
      BATCH
    end

    # Given a host, path to MSI and MSI options, will create a batch file
    #   on the host, returning the path to the randomized batch file and
    #   the randomized log file
    #
    # @param [Host] host An object implementing {Beaker::Hosts}'s interface.
    # @param [String] msi_path The path of the MSI - can be a local Windows
    #   style file path like c:\temp\puppet.msi OR a url like
    #   https://download.com/puppet.msi or file://c:\temp\puppet.msi
    # @param  [Hash{String=>String}] msi_opts MSI installer options
    #   See https://docs.puppetlabs.com/guides/install_puppet/install_windows.html#msi-properties
    #
    # @api private
    # @return [String, String] path to the batch file, patch to the log file
    def create_install_msi_batch_on(host, msi_path, msi_opts)
      timestamp = Time.new.strftime('%Y-%m-%d_%H.%M.%S')
      tmp_path = host.system_temp_path.tr('/', '\\')

      batch_name = "install-puppet-msi-#{timestamp}.bat"
      batch_path = "#{tmp_path}#{host.scp_separator}#{batch_name}"
      log_path = "#{tmp_path}\\install-puppet-#{timestamp}.log"

      Tempfile.open(batch_name) do |tmp_file|
        batch_contents = msi_install_script(msi_path, msi_opts, log_path)

        File.open(tmp_file.path, 'w') { |file| file.puts(batch_contents) }
        host.do_scp_to(tmp_file.path, batch_path, {})
      end

      [batch_path, log_path]
    end

    # Given hosts construct a PATH that includes puppetbindir, facterbindir and hierabindir
    # @param [Host, Array<Host>, String, Symbol] hosts    One or more hosts to act upon,
    #                            or a role (String or Symbol) that identifies one or more hosts.
    # @param [String] msi_path The path of the MSI - can be a local Windows style file path like
    #                   c:\temp\puppet.msi OR a url like https://download.com/puppet.msi or file://c:\temp\puppet.msi
    # @param  [Hash{String=>String}] msi_opts MSI installer options
    #                   See https://docs.puppetlabs.com/guides/install_puppet/install_windows.html#msi-properties
    # @option msi_opts [String] INSTALLIDIR Where Puppet and its dependencies should be installed.
    #                  (Defaults vary based on operating system and intaller architecture)
    #                  Requires Puppet 2.7.12 / PE 2.5.0
    # @option msi_opts [String] PUPPET_MASTER_SERVER The hostname where the puppet master server can be reached.
    #                  (Defaults to puppet)
    #                  Requires Puppet 2.7.12 / PE 2.5.0
    # @option msi_opts [String] PUPPET_CA_SERVER The hostname where the CA puppet master server can be reached, if you are using multiple masters and only one of them is acting as the CA.
    #                  (Defaults the value of PUPPET_MASTER_SERVER)
    #                  Requires Puppet 2.7.12 / PE 2.5.0
    # @option msi_opts [String] PUPPET_AGENT_CERTNAME The node’s certificate name, and the name it uses when requesting catalogs. This will set a value for
    #                  (Defaults to the node's fqdn as discovered by facter fqdn)
    #                  Requires Puppet 2.7.12 / PE 2.5.0
    # @option msi_opts [String] PUPPET_AGENT_ENVIRONMENT The node’s environment.
    #                  (Defaults to production)
    #                  Requires Puppet 3.3.1 / PE 3.1.0
    # @option msi_opts [String] PUPPET_AGENT_STARTUP_MODE Whether the puppet agent service should run (or be allowed to run)
    #                  (Defaults to Manual - valid values are Automatic, Manual or Disabled)
    #                  Requires Puppet 3.4.0 / PE 3.2.0
    # @option msi_opts [String] PUPPET_AGENT_ACCOUNT_USER Whether the puppet agent service should run (or be allowed to run)
    #                  (Defaults to LocalSystem)
    #                  Requires Puppet 3.4.0 / PE 3.2.0
    # @option msi_opts [String] PUPPET_AGENT_ACCOUNT_PASSWORD The password to use for puppet agent’s user account
    #                  (No default)
    #                  Requires Puppet 3.4.0 / PE 3.2.0
    # @option msi_opts [String] PUPPET_AGENT_ACCOUNT_DOMAIN The domain of puppet agent’s user account.
    #                  (Defaults to .)
    #                  Requires Puppet 3.4.0 / PE 3.2.0
    # @option opts [Boolean] :debug output the MSI installation log when set to true
    #                 otherwise do not output log (false; default behavior)
    #
    # @example
    #  install_msi_on(hosts, 'c:\puppet.msi', {:debug => true})
    #
    # @api private
    def install_msi_on(hosts, msi_path, msi_opts = {}, opts = {})
      block_on hosts do |host|
        msi_opts['PUPPET_AGENT_STARTUP_MODE'] ||= 'Manual'
        batch_path, log_file = create_install_msi_batch_on(host, msi_path, msi_opts)
        # Powershell command looses an escaped slash resulting in cygwin relative path
        # See https://github.com/puppetlabs/beaker/pull/1626#issuecomment-621341555
        log_file_escaped = log_file.gsub('\\', '\\\\\\')
        # begin / rescue here so that we can reuse existing error msg propagation
        begin
          # 1641 = ERROR_SUCCESS_REBOOT_INITIATED
          # 3010 = ERROR_SUCCESS_REBOOT_REQUIRED
          on host, Beaker::Command.new("\"#{batch_path}\"", [], { cmdexe: true }), acceptable_exit_codes: [0, 1641, 3010]
        rescue StandardError
          logger.info(file_contents_on(host, log_file_escaped))
          raise
        end

        logger.info(file_contents_on(host, log_file_escaped)) if opts[:debug]

        unless host.is_cygwin?
          # Enable the PATH updates
          host.close

          # Some systems require a full reboot to trigger the enabled path
          host.reboot unless on(host, Beaker::Command.new('puppet -h', [], { cmdexe: true }),
                                accept_all_exit_codes: true).exit_code.zero?
        end

        # verify service status post install
        # if puppet service exists, then pe-puppet is not queried
        # if puppet service does not exist, pe-puppet is queried and that exit code is used
        # therefore, this command will always exit 0 if either service is installed
        #
        # We also take advantage of this output to verify the startup
        # settings are honored as supplied to the MSI
        on host, Beaker::Command.new('sc qc puppet || sc qc pe-puppet', [], { cmdexe: true }) do |result|
          output = result.stdout
          startup_mode = msi_opts['PUPPET_AGENT_STARTUP_MODE'].upcase

          search = case startup_mode # rubocop:disable Style/HashLikeCase
                   when 'AUTOMATIC'
                     { code: 2, name: 'AUTO_START' }
                   when 'MANUAL'
                     { code: 3, name: 'DEMAND_START' }
                   when 'DISABLED'
                     { code: 4, name: 'DISABLED' }
                   end

          raise "puppet service startup mode did not match supplied MSI option '#{startup_mode}'" unless /^\s+START_TYPE\s+:\s+#{search[:code]}\s+#{search[:name]}/.match?(output)
        end

        # (PA-514) value for PUPPET_AGENT_STARTUP_MODE should be present in
        # registry and honored after install/upgrade.
        reg_key = if host.is_x86_64?
                    'HKLM\\SOFTWARE\\Wow6432Node\\Puppet Labs\\PuppetInstaller'
                  else
                    'HKLM\\SOFTWARE\\Puppet Labs\\PuppetInstaller'
                  end
        reg_query_command = %(reg query "#{reg_key}" /v "RememberedPuppetAgentStartupMode" | findstr #{msi_opts['PUPPET_AGENT_STARTUP_MODE']})
        on host, Beaker::Command.new(reg_query_command, [], { cmdexe: true })

        # emit the misc/versions.txt file which contains component versions for
        # puppet, facter, hiera, pxp-agent, packaging and vendored Ruby
        [
          "'%PROGRAMFILES%\\Puppet Labs\\puppet\\misc\\versions.txt'",
          "'%PROGRAMFILES(X86)%\\Puppet Labs\\puppet\\misc\\versions.txt'",
        ].each do |path|
          result = on(host, "cmd /c type #{path}", accept_all_exit_codes: true)
          if result.exit_code.zero?
            logger.info(result.stdout)
            break
          end
        end
      end
    end

    # Installs a specified msi path on given hosts
    # @param [Host, Array<Host>, String, Symbol] hosts    One or more hosts to act upon,
    #                            or a role (String or Symbol) that identifies one or more hosts.
    # @param [String] msi_path The path of the MSI - can be a local Windows style file path like
    #                   c:\temp\foo.msi OR a url like https://download.com/foo.msi or file://c:\temp\foo.msi
    # @param  [Hash{String=>String}] msi_opts MSI installer options
    # @option opts [Boolean] :debug output the MSI installation log when set to true
    #                 otherwise do not output log (false; default behavior)
    #
    # @example
    #  generic_install_msi_on(hosts, 'https://releases.hashicorp.com/vagrant/1.8.4/vagrant_1.8.4.msi', {}, {:debug => true})
    #
    # @api private
    def generic_install_msi_on(hosts, msi_path, msi_opts = {}, opts = {})
      block_on hosts do |host|
        batch_path, log_file = create_install_msi_batch_on(host, msi_path, msi_opts)
        # Powershell command looses an escaped slash resulting in cygwin relative path
        # See https://github.com/puppetlabs/beaker/pull/1626#issuecomment-621341555
        log_file_escaped = log_file.gsub('\\', '\\\\\\')
        # begin / rescue here so that we can reuse existing error msg propagation
        begin
          # 1641 = ERROR_SUCCESS_REBOOT_INITIATED
          # 3010 = ERROR_SUCCESS_REBOOT_REQUIRED
          on host, Beaker::Command.new("\"#{batch_path}\"", [], { cmdexe: true }), acceptable_exit_codes: [0, 1641, 3010]
        rescue StandardError
          logger.info(file_contents_on(host, log_file_escaped))

          raise
        end

        logger.info(file_contents_on(host, log_file_escaped)) if opts[:debug]

        host.close unless host.is_cygwin?
      end
    end
  end
end
