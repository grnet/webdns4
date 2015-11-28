class Domain < ActiveRecord::Base
  self.inheritance_column = :nx

  # List all supported domain types.
  def self.domain_types
    [
      'NATIVE',
      'MASTER',
      'SLAVE',
    ]
  end

  belongs_to :group
  has_many :records
  has_one :soa, class_name: SOA

  validates :group_id, presence: true
  validates :name, uniqueness: true, presence: true
  validates :type, presence: true, inclusion: { in: domain_types }
  validates :master, presence: true, ipv4: true, if: :slave?

  after_create :generate_soa
  after_create :generate_ns

  attr_writer :serial_strategy

  # Get the zone's serial strategy.
  #
  # Returns one of the supported serial strategies.
  def serial_strategy
    @serial_strategy ||= WebDNS.settings[:serial_strategy]
  end

  # Returns true if this a reverse zone.
  def reverse?
    name.end_with?('.in-addr.arpa') || name.end_with?('.ip6.arpa')
  end

  # Returns true if this is a slave zone.
  def slave?
    type == 'SLAVE'
  end

  # Compute subnet for reverse records
  def subnet
    return if not reverse?

    if name.end_with?('.in-addr.arpa')
      subnet_v4
    elsif name.end_with?('.ip6.arpa')
      subnet_v6
    end
  end

  private

  def subnet_v4
    # get ip octets (remove .in-addr.arpa)
    octets = name.split('.')[0...-2].reverse
    return if octets.any? { |_| false }

    mask = 8 * octets.size
    octets += [0, 0, 0, 0]

    ip = IPAddr.new octets[0, 4].join('.')

    [ip, mask].join('/')
  end

  def subnet_v6
    nibbles = name.split('.')[0...-2].reverse
    return if nibbles.any? { |_| false }

    mask = 4 * nibbles.size
    nibbles += [0] * 32

    ip = IPAddr.new nibbles[0, 32].in_groups_of(4).map(&:join).join(':')

    [ip, mask].join('/')
  end

  # Hooks

  def generate_soa
    soa_record = SOA.new(domain: self)

    soa_record.save!
  end

  def generate_ns
    return if slave?
    return if WebDNS.settings[:default_ns].empty?

    WebDNS.settings[:default_ns].each { |ns|
      Record.find_or_create_by!(domain: self, type: 'NS', name: '', content: ns)
    }
  end

end
