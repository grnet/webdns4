Domain.all.destroy_all
Record.all.destroy_all
Group.all.destroy_all
User.all.destroy_all

users = []

users << User.create!(email: 'admin0@example.com', password: 'adminadmin')
5.times { |n|
  users << User.create!(email: "user#{n}@example.com", password: 'useruser')
}

g_admin = Group.create!(name: 'admin')
g1 = Group.create!(name: 'group1')
g2 = Group.create!(name: 'group2')

g_admin.users << users.first
g1.users << users.first
g1.users << users.last
g2.users << users.first

e = g1.domains.create!(name: 'example.com', type: 'NATIVE')
e.records.find_or_create_by!(
  name: 'example.com',
  content: 'ns1.example.com',
  type: 'NS',
)
e.records.find_or_create_by!(
  name: 'example.com',
  content: '"v=spf1 a:mail.example.com -all"',
  type: 'TXT',
)
e.records.find_or_create_by!(
  name: 'example.com',
  content: '"v=spf1 a:mail.example.com -all"',
  type: 'SPF',
)
e.records.find_or_create_by!(
  name: 'ns1.example.com',
  content: '192.0.2.1',
  type: 'A',
)
e.records.find_or_create_by!(
  name: 'www.example.com',
  content: '192.0.2.2',
  type: 'A',
)
e.records.find_or_create_by!(
  name: 'www.example.com',
  content: '2001:db8::2',
  type: 'AAAA',
)
e.records.find_or_create_by!(
  name: 'alias.example.com',
  content: 'www.example.com',
  type: 'CNAME',
)
e.records.find_or_create_by!(
  name: 'mail.example.com',
  content: '192.0.2.3',
  type: 'A',
)
e.records.find_or_create_by!(
  name: 'example.com',
  content: 'mail.example.com',
  type: 'MX',
  prio: 10,
)
e.records.find_or_create_by!(
  name: 'example.com',
  content: 'mail.example.com',
  type: 'MX',
  prio: 30,
)
e.records.find_or_create_by!(
  name: '',
  content: '100 10 "S" "SIP+D2U" "!^.*$!sip:customer-service@example.com!" _sip._udp.example.com',
  type: 'NAPTR',
)

e = g1.domains.create!(name: '4.3.2.1.5.5.5.0.0.8.1.e164.arpa', type: 'NATIVE')
e.records.find_or_create_by!(
  name: '',
  content: '100 10 "U" "E2U+sip" "!^.*$!sip:customer-service@example.com!" .',
  type: 'NAPTR',
)

e = g1.domains.create!(name: '2.0.192.in-addr.arpa', type: 'NATIVE')
e.records.create(
  name: '1',
  content: 'ns1.example.com',
  type: 'PTR',
)
e.records.create(
  name: '2',
  content: 'www.example.com',
  type: 'PTR',
)
e.records.create(
  name: '3',
  content: 'mail.example.com',
  type: 'PTR',
)

e = g2.domains.create!(name: '8.b.d.0.1.0.0.2.ip6.arpa', type: 'NATIVE')
e.records.create(
  name: '2001:db8::2',
  content: 'www.example.com',
  type: 'PTR',
)

