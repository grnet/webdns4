WebDNS = Base

WebDNS.settings[:soa_defaults] = {
  primary_ns: 'ns.example.com',
  contact: 'domainmaster@example.com',
  serial: 1,
  refresh: 10_800,
  retry: 3600,
  expire: 604_800,
  nx: 3600
}

