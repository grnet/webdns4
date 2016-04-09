class Domain < ActiveRecord::Base
  class NotAChild < StandardError; end
  self.inheritance_column = :nx

  # List all supported domain types.
  def self.domain_types
    [
      'NATIVE',
      'MASTER',
      'SLAVE',
    ]
  end

  # List domain types that can be created.
  def self.allowed_domain_types
    domain_types - WebDNS.settings[:prohibit_domain_types]
  end

  # List parent authorities
  def self.dnssec_parent_authorities
    WebDNS.settings[:dnssec_parent_authorities].keys.map(&:to_s)
  end

  # Fire event after transaction commmit
  # Changing state inside a hook messes things up,
  # this trick handles that
  attr_accessor :fire_event

  belongs_to :group
  has_many :jobs
  has_many :records
  # BUG in bump_serial_trigger
  has_one :soa, -> { unscope(where: :type).where(type: 'soa') }, class_name: SOA
  belongs_to :dnssec_policy

  validates :group_id, presence: true
  validates :name, uniqueness: true, presence: true
  validates :type, presence: true, inclusion: { in: domain_types }
  validates :master, presence: true, ipv4: true, if: :slave?

  validates :dnssec, inclusion: { in: [false] }, unless: :dnssec_elegible?
  validates :dnssec_parent_authority, inclusion: { in: dnssec_parent_authorities }, if: :dnssec?
  validates :dnssec_parent, hostname: true, if: :dnssec?
  validates :dnssec_policy_id, presence: true, if: :dnssec?

  after_create :generate_soa
  after_create :generate_ns

  after_create :install
  before_save :check_convert
  before_save :check_dnssec_parent_authority, if: :dnssec?
  after_commit :after_commit_event

  attr_writer :serial_strategy

  def self.dnssec_progress(current_state)
    progress = [
      :pending_signing, # 1/3
      :wait_for_ready,  # 2/3
      :pending_ds]      # 3/3
    idx = progress.index(current_state.to_sym)
    return if idx.nil?

    [idx+1, progress.size].join('/')
  end

  state_machine initial: :initial do
    after_transition(any => :pending_install) { |domain, _t| Job.add_domain(domain) }
    after_transition(any => :pending_remove) { |domain, _t| Job.shutdown_domain(domain) }
    after_transition(any => :pending_ds_removal) { |domain, _t| Job.dnssec_drop_ds(domain) }
    after_transition(any => :pending_signing) { |domain, _t| Job.dnssec_sign(domain) }
    after_transition(any => :wait_for_ready) { |domain, _t| Job.wait_for_ready(domain) }
    after_transition(any => :pending_ds) { |domain, t| Job.dnssec_push_ds(domain, *t.args) }
    after_transition(any => :pending_ds_rollover) { |domain, t| Job.dnssec_rollover_ds(domain, *t.args) }
    after_transition(any => :pending_plain) { |domain, _t| Job.convert_to_plain(domain) }
    after_transition(any => :destroy) { |domain, _t| domain.destroy }

    # User events
    event :install do
      transition initial: :pending_install
    end

    event :dnssec_sign do
      transition operational: :pending_signing
    end

    event :signed do
      transition pending_signing: :wait_for_ready
    end

    event :push_ds do
      transition wait_for_ready: :pending_ds, operational: :pending_ds_rollover
    end

    event :plain_convert do
      transition operational: :pending_plain
    end

    event :remove do
      transition [:operational, :pending_ds_removal] => :pending_remove
    end

    event :full_remove do
      transition operational: :pending_ds_removal
    end

    # Machine events
    event :installed do
      transition pending_install: :operational
    end

    event :converted do
      transition [:pending_ds, :pending_plain] => :operational
    end

    event :complete_rollover do
      transition pending_ds_rollover: :operational
    end

    event :cleaned_up do
      transition pending_remove: :destroy
    end

    event :ksk_rollover_detected do
      transition operational: :ksk_rollover
    end
  end

  # Returns true if this domain is elegigble for DNSSEC
  def dnssec_elegible?
    return false if slave?

    true
  end

  # Returns the zone serial if a SOA record exists
  def serial
    return if !soa

    soa.serial
  end

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

  # Returns true if this a ENUM zone.
  def enum?
    name.end_with?('.e164.arpa')
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

  def self.replace_ds(parent, child, records)
    records ||= []
    parent = find_by_name!(parent)
    fail NotAChild if not child.end_with?(parent.name)

    existing = parent.records.where(name: child, type: 'DS')
    recs = records.map { |rec| DS.new(domain: parent, name: child, content: rec) }

    ActiveRecord::Base.transaction do
      existing.destroy_all
      recs.map(&:save!)
    end
  end

  # Apply bulk to operations to the zones
  #
  # 1) Deletions
  # 2) Changes
  # 3) Additions
  def bulk(opts)
    deletes = opts[:deletes] || []
    changes = opts[:changes] || {}
    additions = opts[:additions] || {}
    errors = Hash.new { |h, k| h[k] = {} }
    operations = Hash.new { |h, k| h[k] = [] }

    ActiveRecord::Base.transaction do
      # Deletes
      to_delete = records.where(id: deletes).index_by(&:id)
      deletes.each { |rec_id|
        if rec = to_delete[Integer(rec_id)]
          rec.destroy
          operations[:deletes] << rec
          next
        end

        errors[:deletes][rec_id] = 'Deleted record not found'
      }

      # Changes
      to_change = records.where(id: changes.keys).index_by(&:id)
      changes.each {|rec_id, changes|
        if rec = to_change[Integer(rec_id)]
          operations[:changes] << rec
          errors[:changes][rec_id] = rec.errors.full_messages.join(', ') if !rec.update(changes)
          next
        end

        errors[:changes][rec_id] = 'Changed record not found'
      }

      # Additions
      additions.each { |inc, attrs|
        rec = records.new(attrs)
        operations[:additions] << rec
        errors[:additions][inc] = rec.errors.full_messages.join(', ') if !rec.save
      }

      raise ActiveRecord::Rollback if errors.any?
    end

    [operations, errors]
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

  def check_convert
    return if !dnssec_changed?

    event = dnssec ? :dnssec_sign : :plain_convert
    if state_events.include?(event)
      self.fire_event = event # Schedule event for after commit
      return true
    end

    errors.add(:dnssec, 'You cannot modify dnssec settings in this state!')
    false
  end

  def check_dnssec_parent_authority
    cfg = WebDNS.settings[:dnssec_parent_authorities][dnssec_parent_authority.to_sym]
    return if !cfg[:valid]

    return true if cfg[:valid].call(dnssec_parent)

    errors.add(:dnssec_parent_authority, 'Parent zone is not accepted for the selected parent authority!')
    false
  end

  def after_commit_event
    return if !fire_event

    fire_state_event(fire_event)
    self.fire_event = nil
  end
end
