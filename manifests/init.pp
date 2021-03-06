# Class: smartconnect_dns
# ===========================
#
# Setting up a caching only nameserver locally on servers that need to directly
# mount storage on an Isilon cluster.
#
# Parameters
# ----------
#
# Document parameters here.
#
# * `domain`
# The domain for which smart connect will provide ips.  e.g. sc.sub.example.com
# Expecting the mounts specify something like nas-cluster.sc.sub.example.com
#
# * `nameserver_ip`
# The ip address of the nameserver to forward requests in the domain.
#
# * `other_ns_ips`
# defaults to hiera lookup for resolv_conf::nameservers.
# Used in:
#   forwarding: The other nameserver ips for all non-smartconnect requests.  
#   resolv_conf: .
# 
#
# Examples
# --------
#
# @example
#    class { 'smartconnect_dns':
#      domain => 'sc.example.com'
#      nameserver_ip => '10.10.40.50'
#    }
#
# Authors
# -------
#
# Author Name <grosscol@gmail.com>
#
class smartconnect_dns (
  String $domain,
  String $nameserver_ip,
  Array $other_ns_ips = []
) {
  include ::stdlib
  require smartconnect_dns::prereqs

  # Get nameservers array for forwarders list and resolv_conf
  #   Try hiera lookup if there aren't any parameter provided ips 
  if empty($other_ns_ips) {
    $std_nameservers = lookup("resolv_conf::nameservers", Array, 'first', [])
  }
  else {
    $std_nameservers = $other_ns_ips
  }

  # Prepend localhost to nameservers array for use with resolv_conf
  $mod_nameservers = concat( ['127.0.0.1'], $std_nameservers)

  # Use module specific resolv_conf config
  # Get resolv_conf::searchpath arrary from hiera
  class { 'resolv_conf':
    nameservers => $mod_nameservers
  } 

  # Static BIND9 config files to configure named to only resolve smart connect requests
  file { 'named.conf':
    path => '/etc/bind/named.conf',
    source => 'puppet:///modules/smartconnect_dns/named.conf',
    notify => Service['bind9']
  }

  # Template configs for smart connect zone
  file { 'named.conf.local':
    path => '/etc/bind/named.conf.local',
    content => template('smartconnect_dns/named.conf.local.erb'),
    notify => Service['bind9']
  }
  file { 'named.conf.options':
    path => '/etc/bind/named.conf.options',
    content => template('smartconnect_dns/named.conf.options.erb'),
    notify => Service['bind9']
  }

  # Service for bind9 to be notified and restarted when configs change.
  service { 'bind9':
    ensure => running
  }
}
