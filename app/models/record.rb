require 'ipaddr'
require_dependency 'drop_privileges_validator'

class Record < ActiveRecord::Base
  belongs_to :domain
  # Powerdns inserts empty records on slave zones,
  # we want to hide them
  #
  # http://mailman.powerdns.com/pipermail/pdns-users/2013-December/010389.html
  default_scope { where.not(type: nil) }

  # List all supported DNS RR types.
  def self.record_types
    [
      'A', 'AAAA', 'CNAME',
      'MX',
      'TXT', 'SPF', 'SRV', 'SSHFP',
      'SOA', 'NS',
      'PTR', 'NAPTR',
      'DS'
    ]
  end

  # List types usually used in forward zones.
  def self.forward_records
    record_types - ['SOA', 'PTR']
  end

  # List types usually used in reverse zones.
  def self.reverse_records
    ['PTR', 'CNAME', 'TXT', 'NS', 'NAPTR', 'DS']
  end

  # List types usually used in enum zones.
  def self.enum_records
    ['NAPTR', 'CNAME', 'TXT', 'NS', 'DS']
  end

  # List types that can be touched by a simple user.
  def self.allowed_record_types
    record_types - WebDNS.settings[:prohibit_records_types]
  end

  validates :name, presence: true
  validates :type, inclusion: { in: record_types }

  # http://mark.lindsey.name/2009/03/never-use-dns-ttl-of-zero-0.html
  validates_numericality_of :ttl,
                            allow_nil: true, # Default pdns TTL
                            only_integer: true,
                            greater_than: 0,
                            less_than_or_equal_to: 2_147_483_647

  # Don't allow the following actions on drop privileges mode
  validate :no_touching_for_slave_zones, if: -> { domain.slave? }

  validates_drop_privileges :type,
                            message: 'You cannot touch that record!',
                            unless: -> { Record.allowed_record_types.include?(type) }
  validates_drop_privileges :name,
                            message: 'You cannot touch top level NS records!',
                            if: -> { type == 'NS' && domain_record? }

  validates_uniqueness_of :name,
                          :scope => [:domain, :type, :content],
                          message: "There already exists a record with the same name,
                            type and content."

  before_validation :guess_reverse_name
  before_validation :set_name
  after_save :update_zone_serial
  after_destroy :update_zone_serial

  before_create :validate_unique_cname
  before_create :generate_classless_delegations, unless: -> { domain.slave? }
  before_destroy :delete_classless_delegations, unless: -> { domain.slave? }

  # Smart sort a list of records.
  #
  # Order by:
  # * Top level records
  # * Record name
  # * SOA
  # * NS
  # * Friendly type
  # * Priority
  # * Content
  #
  # records - The list of records to order.
  #
  # Returns the list sorted.
  def self.smart_order(records)
    records.sort_by { |r|
      [
        r.domain_record? ? 0 : 1,   # Zone records
        r.classless_delegated? ? 1 : 0,
        r.name,
        r.type == 'SOA' ? 0 : 1,
        r.type == 'NS' ? 0 : 1,
        record_types.index(r.type), # Friendly type
        r.prio || 0,
        r.content
      ]
    }
  end

  def self.search(query)
    wild_search = "%#{query}%" # !index_friendly

    where('name like :q or content like :q', q: wild_search)
  end

  # Get the a short name for the record (without the zone suffix).
  #
  # Returns a string.
  def short
    return '' if name == domain.name
    return '' if name.blank?

    File.basename(name, ".#{domain.name}")
  end

  # Returns true if this is a zone record.
  def domain_record?
    name.blank? || name == domain.name
  end

  # Find out if the record is edittable.
  #
  # by - Editable by :user or :admin.
  #
  # Returns true if the record is editable.
  def editable?(by = :user)
    return false if domain.slave?
    return false if classless_delegated?

    case by
    when :user
      return false unless Record.allowed_record_types.include?(type)
      return false if type == 'NS' && domain_record?
    end

    true
  end

  # Find out this record type supports priorities.
  #
  # We set this to false by default, record types that support priorities.
  # shoule override this.
  #
  # Returns true this record type support priorities.
  def supports_prio?
    false
  end

  # Make sure rails generates record specific urls for all record types.
  #
  # Overrides default rails STI behavior.
  def self.model_name
    return super if self == Record

    Record.model_name
  end

  # Generate the usual admin friendly DNS record line.
  #
  # Returns a string.
  def to_dns
    [name, ttl, 'IN', type, supports_prio? ? prio : nil, content].compact.join(' ')
  end

  # Generate a shorter version of the DNS record line.
  #
  # Returns a string.
  def to_short_dns
    [name, 'IN', type].join(' ')
  end

  def to_api
    Hash[
      :name, name,
      :content, content,
      :type, type,
      :ttl, ttl,
      :prio, prio,
      :disabled, disabled
    ].with_indifferent_access
  end

  def classless_delegated?
    return false if not type == 'CNAME'
    return false if not domain.name.end_with?('.in-addr.arpa')

    network, mask = parse_delegation(content)
    return false if network.nil?

    octet = name.split('.').first.to_i
    return true if octet >= network
    return true if octet <= network + 2 ^ (32 - mask) - 1 # max

    false
  end

  def classless_delegation?
    return true if classless_delegation

    false
  end

  def as_bulky_json
    Hash[
      id: id,
      name: name,
      type: type,
      ttl: ttl,
      prio: prio,
      content: content,
      disabled: disabled
    ]
  end
  private

  # Validations

  def no_touching_for_slave_zones
    # Allow automatic SOA creation for slave zones
    # powerdns needs a valid serial to compare it with master
    return if type == 'SOA' && validation_context == :create

    errors.add(:type, 'This is a slave zone!')
  end

  # Hooks

  def guess_reverse_name
    return if not type == 'PTR'
    return if not domain.reverse?
    return if name.blank?

    reverse = IPAddr.new(name).reverse
    self.name = reverse if reverse.end_with?(domain.name)
  rescue IPAddr::InvalidAddressError # rubycop:disable HandleExceptions
  end

  # Powerdns expects full domain names
  def set_name
    self.name = domain.name if name.blank?
    self.name = "#{name}.#{domain.name}" if not name.end_with?(domain.name)
  end

  def remove_terminating_dot
    self.content = content.gsub(/\.+\Z/, '')
  end

  def update_zone_serial
    # SOA records handle serial themselves
    return true if type == 'SOA'
    return true if !domain

    domain.soa.bump_serial!
  end

  def classless_delegation
    return if not type == 'NS'
    return if not domain.name.end_with?('.in-addr.arpa')

    network, mask = parse_delegation(name)
    return if network.nil?

    range = IPAddr.new("0.0.0.#{network}/#{mask}").to_range
    return if !range.first.to_s.end_with?(".#{network}")

    range.map { |ip|
      octet = ip.to_s.split('.').last
      "#{octet}.#{domain.name}"
    }
  end

  def parse_delegation(value)
    first, _rest = value.split('.', 2)
    first.gsub!('-', '/')
    return if !first['/']

    network, mask = first.split('/', 2).map { |i| Integer(i).abs }
    return if [network, mask].join('/') != first
    return if mask <= 24
    return if mask > 31
    return if network > 255

    [network, mask]
  rescue ArgumentError # Not an integer
  end

  def delete_classless_delegations
    rnames = classless_delegation
    return unless rnames

    # Check if we have another NS for the same delegation
    return if domain.records.where(type: 'NS', name: name)
               .where.not(id: id).exists?

    # Delete all CNAMEs
    domain.records.where(name: rnames,
                         type: 'CNAME',
                         content: name).delete_all
  end

  def generate_classless_delegations
    rnames = classless_delegation
    return unless rnames

    # Make sure no record exists for a delegated domain
    if domain.records.where(name: rnames)
        .where.not(content: name).exists?

      errors.add(:name, 'Records already exist for the delegated octets!')
      return false
    end

    rnames.each { |rname|
      CNAME.find_or_create_by!(
        type: 'CNAME',
        domain: domain,
        name: rname,
        content: name
      )
    }
  end

  def self.to_fqdn(name, domain)
    return name if name.end_with?(domain)

    "#{name}.#{domain}"
  end

  def validate_unique_cname
    return if !domain.records.where(type: 'CNAME', name: name).exists?

    errors.add(:name, 'There exists a CNAME record with the same name')
    return false
  end
end
