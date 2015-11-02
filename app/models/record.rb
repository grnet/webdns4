require 'ipaddr'

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

  validates :name, presence: true
  validates :type, inclusion: { in: record_types }

  before_validation :guess_reverse_name
  before_validation :set_name
  after_save :update_zone_serial
  after_destroy :update_zone_serial

  def short
    return '' if name == domain.name
    return '' if name.blank?

    File.basename(name, ".#{domain.name}")
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
    [name, 'IN', type, supports_prio? ? prio : nil, content].compact.join(' ')
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
