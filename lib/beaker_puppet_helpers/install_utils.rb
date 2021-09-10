# frozen_string_literal: true

require 'beaker/command'

module BeakerPuppetHelpers
  # Methods to install Puppet
  class InstallUtils
    # @api private
    REPOS = {
      release: {
        apt: 'https://apt.puppet.com',
        yum: 'https://yum.puppet.com'
      },
      nightly: {
        apt: 'https://nightlies.puppet.com/apt',
        yum: 'https://nightlies.puppet.com/yum'
      }
    }.freeze

    # Install official Puppet release repository configuration on host(s).
    #
    # @example Install Puppet 7
    #   install_puppet_release_repo_on(hosts, 'puppet7')
    #
    # @param [Beaker::Host] host
    #   A host to act upon.
    # @param [String] collection
    #   The collection to install. The default (puppet) is the latest
    #   available version.
    # @param [Boolean] nightly
    #   Whether to install nightly or release packages
    #
    # @note This method only works on redhat-like and debian-like hosts. There
    #   are no official Puppet releases for other platforms.
    #
    def self.install_puppet_release_repo_on(host, collection = 'puppet', nightly: false)
      repos = REPOS[nightly ? :nightly : :release]

      variant, version, _arch = host['packaging_platform'].split('-', 3)

      case variant
      when 'el', 'fedora', 'sles', 'cisco-wrlinux'
        # sles 11 and later do not handle gpg keys well. We can't
        # automatically import the keys because of sad things, so we
        # have to manually import it once we install the release
        # package. We'll have to remember to update this block when
        # we update the signing keys
        if variant == 'sles' && version >= '11'
          %w[puppet puppet-20250406].each do |gpg_key|
            wget_on(host, "https://yum.puppet.com/RPM-GPG-KEY-#{gpg_key}") do |filename|
              host.exec(Beaker::Command.new("rpm --import '#{filename}'"))
            end
          end
        end

        url = "#{repos[:yum]}/#{collection}-release-#{variant}-#{version}.noarch.rpm"
        host.install_package(url)
      when 'debian', 'ubuntu'
        url = "#{repos[:apt]}/#{collection}-release-#{host['platform'].codename}.deb"
        wget_on(host, url) do |filename|
          host.install_package(filename)
        end
        host.exec(Beaker::Command.new('apt-get update'))

        # On Debian we can't count on /etc/profile.d
        host.add_env_var('PATH', '/opt/puppetlabs/bin')
      else
        raise "No repository installation step for #{variant} yet..."
      end
    end

    # Determine the Puppet package name
    #
    # @param [Beaker::Host] host
    #   The host to act on
    # @param [Boolean] prefer_aio
    #   Whether to prefer AIO packages or OS packages
    # @return [String] The Puppet package name
    def self.puppet_package_name(host, prefer_aio: true)
      case host['packaging_platform'].split('-', 3).first
      when /el-|fedora|sles|cisco_|debian|ubuntu/
        prefer_aio ? 'puppet-agent' : 'puppet'
      when /freebsd/
        'sysutils/puppet'
      else
        'puppet'
      end
    end

    # @param [Beaker::Host] host
    #   The host to act on
    # @api private
    def self.wget_on(host, url)
      extension = File.extname(url)
      name = File.basename(url, extension)
      # Can't use host.tmpfile since we need to set an extension
      target = host.exec(Beaker::Command.new("mktemp -t '#{name}-XXXXXX#{extension}'")).stdout.strip
      begin
        host.exec(Beaker::Command.new("wget -O '#{target}' '#{url}'"))
        yield target
      ensure
        host.rm_rf(target)
      end
    end
  end
end
