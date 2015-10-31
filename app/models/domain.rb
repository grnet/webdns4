class Domain < ActiveRecord::Base
  self.inheritance_column = :nx

  def self.domain_types
    [
      'NATIVE',
      'MASTER',
      'SLAVE',
    ]
  end

  has_many :records
  has_one :soa, class_name: SOA

  validates :name, uniqueness: true, presence: true
  validates :type, presence: true, inclusion: { in: domain_types }

  after_create :generate_soa

  attr_writer :serial_strategy
  def serial_strategy
    @serial_strategy ||= WebDNS.settings[:serial_strategy]
  end

  def reverse?
    name.end_with?('.in-addr.arpa') || name.end_with?('.ip6.arpa')
  end

  private

  # Hooks
  def generate_soa
    soa_record = SOA.new(domain: self)
    soa_record.save
  end

end
