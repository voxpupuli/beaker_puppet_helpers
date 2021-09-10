# @summary a dummy class to verify the module is installed
class dummy {
  file { '/beaker-puppet-helpers-test':
    ensure  => 'file',
    content => 'Hello World!',
    mode    => '0644',
  }
}
