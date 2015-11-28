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
end
