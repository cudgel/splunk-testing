## Active Configurations ##


$role = hiera('role', undef)
hiera_include('classes')
# and differences.
# Run stages
stage { 'first':
      before => Stage['main'],
    }
stage { 'last': }
Stage['main'] -> Stage['last']

# DEFAULT NODE
# Node definitions in this file are merged with node data from the console. See
# http://docs.puppetlabs.com/guides/language_guide.html#nodes for more on
# node definitions.

# The default node definition matches any node lacking a more specific node
# definition. If there are no other nodes in this file, classes declared here
# will be included in every node's catalog, *in addition* to any classes
# specified in the console for that node.

node default {
  #incude a role on any node that specifies it's role via a trusted fact at provision time
  #https://docs.puppetlabs.com/puppet/latest/reference/lang_facts_and_builtin_vars.html#trusted-facts
  #https://docs.puppetlabs.com/puppet/latest/reference/ssl_attributes_extensions.html#aws-attributes-and-extensions-population-example

  if !empty( $trusted['extensions']['pp_role'] ) {
    include "role::${trusted['extensions']['pp_role']}"
  }

  # This is where you can declare classes for all nodes.
  # Example:
  #   class { 'my_class': }
}
  # This is where you can declare classes for all nodes.
  # Example:
  #   class { 'my_class': }
