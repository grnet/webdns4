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

WebDNS.settings[:serial_strategy] = Strategies::Date

# Don't allow to create SOA records
WebDNS.settings[:prohibit_records_types] = ['SOA']

WebDNS.settings[:mail_from] = 'webdns@example.com'
