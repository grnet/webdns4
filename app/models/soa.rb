class SOA < Record
  validates :domain_id, uniqueness: true
  validates_numericality_of :serial, :refresh, :retry, :expire
  validates_presence_of :contact

  SOA_DEFAULTS = WebDNS.settings[:soa_defaults]
  SOA_FIELDS = SOA_DEFAULTS.keys

  SOA_FIELDS.each { |soa_entry|
    attr_accessor soa_entry
  }

  # Handle SOA Fields
  after_initialize :set_soa_fields

  # Load soa fields on reload
  def reload_with_soa_fields(*args)
    reload_without_soa_fields(*args).tap {
      set_soa_fields
    }
  end
  alias_method_chain :reload, :soa_fields

  before_validation :set_content
  before_validation :update_serial, on: :update

  def bump_serial!
    with_lock {
      reload
      self.serial += 1
      save!
    }
  end

  def serial_changed?
    return false if not self.content_changed?

    serial_index = SOA_FIELDS.index(:serial)
    old, new = content_change.map { |c|
      (c || '').split(/\s+/)[serial_index]
    }

    old != new
  end

  private

  # Callbacks

  def set_soa_fields
    content_values = (content || '').split(/\s+/)
    SOA_DEFAULTS.each { |field, default_value|
      val = content_values.shift || default_value
      val = Integer(val) if default_value.is_a?(Integer)
      send("#{field}=", val)
    }
  end

  def set_content
    self.content = SOA_FIELDS.map { |field| send(field) }.join(' ')
  end

  def update_serial
    # Don't update if nothing has changed
    return if not self.content_changed?
    # Don't updade if serial is already changed
    return if self.serial_changed?

    self.serial += 1
    set_content
  end

end
