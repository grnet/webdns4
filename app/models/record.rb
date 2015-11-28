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
      'PTR', 'NAPTR'
    ]
  end

  # List types usually used in forward zones.
  def self.forward_records
    record_types - ['SOA', 'PTR']
  end

  # List types usually used in reverse zones.
  def self.reverse_records
    ['PTR', 'CNAME', 'TXT', 'NS', 'NAPTR']
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

  before_validation :guess_reverse_name
  before_validation :set_name
  after_save :update_zone_serial
  after_destroy :update_zone_serial

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
        r.name,
        r.type == 'SOA' ? 0 : 1,
        r.type == 'NS' ? 0 : 1,
        record_types.index(r.type), # Friendly type
        r.prio,
        r.content
      ]
    }
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

end
