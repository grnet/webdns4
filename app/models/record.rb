require 'ipaddr'
require_dependency 'drop_privileges_validator'

class Record < ActiveRecord::Base
  belongs_to :domain

  def self.record_types
    [
      'SOA', 'NS', 'CNAME',
      'A', 'AAAA',
      'MX',
      'TXT', 'SPF', 'SRV', 'SSHFP',
      'PTR',
    ]
  end

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

  def short
    return '' if name == domain.name
    return '' if name.blank?

    File.basename(name, ".#{domain.name}")
  end

  def domain_record?
    name.blank? || name == domain.name
  end

  # Editable by a non-admin user
  def editable?
    return false unless Record.allowed_record_types.include?(type)
    return false if type == 'NS' && domain_record?

    true
  end

  def supports_prio?
    false
  end

  # Create record specific urls for all record types
  #
  # Overrides default rails STI
  def self.model_name
    return super if self == Record

    Record.model_name
  end

  def to_dns
    [name, ttl, 'IN', type, supports_prio? ? prio : nil, content].compact.join(' ')
  end

  private

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

  def update_zone_serial
    # SOA records handle serial themselves
    return true if type == 'SOA'

    domain.soa.bump_serial!
  end

end
