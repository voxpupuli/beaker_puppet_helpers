# frozen_string_literal: true

require 'beaker_puppet_helpers'

test_name '#install_puppet_release_repo_on' do
  block_on hosts, run_in_parallel: true do |host|
    BeakerPuppetHelpers::InstallUtils.install_puppet_release_repo_on(host) if host['type'] == 'aio'
  end
end

test_name 'install puppet' do
  step 'run installation' do
    block_on hosts, run_in_parallel: true do |host|
      package_name = BeakerPuppetHelpers::InstallUtils.puppet_package_name(host, prefer_aio: host['type'] == 'aio')
      host.install_package(package_name)
    end
  end

  step 'run puppet' do
    on hosts, 'puppet --version', run_in_parallel: true
  end
end
