# frozen_string_literal: true

require 'beaker_puppet_helpers'

test_name '#install_puppet_module_via_pmt_on' do
  install_puppet_module_via_pmt_on(hosts, 'puppetlabs-stdlib')
end

test_name '#install_local_module_on' do
  step 'install module' do
    install_local_module_on(hosts, 'acceptance/dummy')
  end

  step 'clean result' do
    on hosts, 'rm -f /beaker-puppet-helpers-test'
  end

  step 'apply module' do
    on hosts, 'echo include dummy | puppet apply', run_in_parallel: true
  end

  step 'verify' do
    block_on hosts, run_in_parallel: true do |host|
      assert_equal('Hello World!', file_contents_on(host, '/beaker-puppet-helpers-test'))
    end
  end
end
