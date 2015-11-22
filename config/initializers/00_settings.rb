WebDNS = Base

WebDNS.settings[:soa_defaults] = {
  primary_ns: 'ns1.example.com',
  contact: 'domainmaster@example.com',
  serial: 1,
  refresh: 10_800,
  retry: 3600,
  expire: 604_800,
  nx: 3600
}
WebDNS.settings[:default_ns] = [
  'ns1.example.com',
  'ns2.example.com'
]

WebDNS.settings[:serial_strategy] = Strategies::Date

WebDNS.settings[:prohibit_records_types] = []

WebDNS.settings[:mail_from] = 'webdns@example.com'
WebDNS.settings[:admin_group] = 'admin'
