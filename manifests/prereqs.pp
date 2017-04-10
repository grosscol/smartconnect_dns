# Class: smartconnect_dns::prereqs
# 
# Prerequisites that need to be present prior to smartconnect_dns.

class smartconnect_dns::prereqs {
  include ::apt
  ensure_packages(['bind9'], {'ensure' => 'present'})
}
