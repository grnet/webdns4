module RecordsHelper

  # Smart suffix for records
  #
  # On forward zones returns the zone name.
  # On reverse zones returns the zone name but also tries to infer the subnet.
  #
  # Returns a smart suffix string.
  def name_field_append(record)
    return ".#{record.domain.name}" if not record.domain.reverse?

    ".#{record.domain.name} (#{record.domain.subnet})"
  end

  # List of record types usually used for that domain type
  def record_types_for_domain(domain)
    return Record.reverse_records if domain.reverse?
    return Record.enum_records if domain.enum?

    Record.forward_records
  end
end
