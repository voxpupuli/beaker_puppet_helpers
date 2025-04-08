# frozen_string_literal: true

require 'beaker/command'

module BeakerPuppetHelpers
  # Methods to install Puppet
  class InstallUtils
    # @api private
    REPOS = {
      openvox: {
        release: {
          apt: 'https://apt.voxpupuli.org/',
          yum: 'https://yum.voxpupuli.org/',
        },
      },
      puppet: {
        release: {
          apt: 'https://apt.puppet.com',
          yum: 'https://yum.puppet.com',
        },
      },
    }.freeze

    # returns the used implementation (puppet or openvox)
    #
    # @param [String] collection
    #   The used collection (puppet7, openvox8...)
    # @return [String] the implementation
    def self.implementation_from_collection(collection)
      if collection == 'none'
        'puppet'
      else
        collection.gsub(/\d+/, '')
      end
    end

    # Install official Puppet release repository configuration on host(s).
    #
    # @example Install Puppet 7
    #   install_puppet_release_repo_on(hosts, 'puppet7')
    #
    # @param [Beaker::Host] host
    #   A host to act upon.
    #
    # @param [String] collection
    #   The collection to install. The default (puppet) is the latest
    #   available version. Can also be openvox7, puppet8 and others.
    #   Method is called from beaker_install_helpers
    #
    # @note This method only works on redhat-like and debian-like hosts. There
    #   are no official Puppet releases for other platforms.
    #
    def self.install_puppet_release_repo_on(host, collection = 'puppet')
      implementation = implementation_from_collection(collection)
      repos = REPOS[implementation.to_sym][:release]

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
        relname = (implementation == 'openvox') ? "#{variant}#{version}" : host['platform'].codename
        url = "#{repos[:apt]}/#{collection}-release-#{relname}.deb"
        wget_on(host, url) do |filename|
          host.install_package(filename)
        end
        if implementation == 'puppet'
          # the old key puppet-20250406 expired, `future` is a new one, without expiration date
          #   kjetilho | bastelfreak: the FUTURE key is the same key used since 2019, just without the expire date
          #   kjetilho | so it will work with all new and old repos
          # because of ^ statement from IRC, we're only importing the newest key here
          # We need the chmod to avoid:
          #   The key(s) in the keyring /etc/apt/trusted.gpg.d/puppet.asc are ignored as the file is not readable by user '_apt' executing apt-key.
          wget_on(host, 'https://apt.puppet.com/DEB-GPG-KEY-future') do |filename|
            host.exec(Beaker::Command.new("mv '#{filename}' /etc/apt/trusted.gpg.d/puppet.asc && chmod 644 /etc/apt/trusted.gpg.d/puppet.asc"))
          end
        end
        host.exec(Beaker::Command.new('apt-get update'))

        # On Debian we can't count on /etc/profile.d
        host.add_env_var('PATH', '/opt/puppetlabs/bin')
      else
        raise "No repository installation step for #{variant} yet..."
      end
    end

    # Determine the correct package name, based on implementation, AIO and OS
    #
    # @param [Beaker::Host] host
    #   The host to act on
    # @param [Boolean] prefer_aio
    #   Whether to prefer AIO packages or OS packages
    # @param [String] implementation
    #   If we are on OpenVox or Perforce
    # @return [String] the package name
    def self.package_name(host, prefer_aio: true, implementation: 'openvox')
      case implementation
      when 'openvox'
        openvox_package_name
      when 'puppet'
        puppet_package_name(host, prefer_aio: prefer_aio)
      when 'none'
        'puppet'
      else
        raise StandardError, "Unknown requirement '#{implementation}'"
      end
    end

    # Determine if we need the Perforce or OpenVox Package, based on the collection
    #
    # @param [Beaker::Host] host
    #   The host to act on
    # @param collection
    #   The used collection (none, puppet7, openvox8, ...)
    # @param [Optional[Boolean]] prefer_aio
    #   Whether to prefer AIO packages or OS packages. If not specified, it's
    #   derived from the collection
    # @return [String] the package name
    def self.collection2packagename(host, collection, prefer_aio: nil)
      prefer_aio = collection != 'none' if prefer_aio.nil?

      implementation = implementation_from_collection(collection)
      package_name(host, prefer_aio: prefer_aio, implementation: implementation)
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
      when 'debian'
        # 12 started to ship puppet-agent with puppet as a legacy package
        (prefer_aio || host['packaging_platform'].split('-', 3)[1].to_i >= 12) ? 'puppet-agent' : 'puppet'
      when /el|fedora|sles|cisco_/
        prefer_aio ? 'puppet-agent' : 'puppet'
      when /freebsd/
        'sysutils/puppet8'
      when 'ubuntu'
        # 23.04 started to ship puppet-agent with puppet as a legacy package
        (prefer_aio || host['packaging_platform'].split('-', 3)[1].to_i >= 2304) ? 'puppet-agent' : 'puppet'
      else
        'puppet'
      end
    end

    # Determine the openvox package name
    #
    # @return [String] The openvox package name
    def self.openvox_package_name
      'openvox-agent'
    end

    # @param [Beaker::Host] host
    #   The host to act on
    # @api private
    def self.wget_on(host, url)
      extension = File.extname(url)
      name = File.basename(url, extension)
      target = host.tmpfile(name, extension)
      begin
        host.exec(Beaker::Command.new("wget -O '#{target}' '#{url}'"))
        yield target
      ensure
        host.rm_rf(target)
      end
    end
  end
end
