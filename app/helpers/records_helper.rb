module RecordsHelper

  DNSSEC_SERIAL_HELP = 'On DNSSEC enabled domains the actual zone serial wont be the same. This is because autosigning bumps the zone serial automatically.'
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

  def editable_record_attr(rec, attr)
    return soa_content(rec) if rec.type == 'SOA' && attr == :content
    return rec.read_attribute(attr) if rec.type == 'SOA' || !can_edit?(rec)

    link_to(
      rec.read_attribute(attr),
      "#edit-record-#{rec.id}-#{attr}",
      class: 'editable',
      data: { pk: rec.id, name: attr, type: 'text', url: editable_domain_records_path(rec.domain_id) }
    )
  end

  def soa_content(rec)
    SOA::SOA_FIELDS.map { |attr|
      value = rec.send(attr)
      value = content_tag(:abbr, value, title: DNSSEC_SERIAL_HELP) if attr.to_s == 'serial' && rec.domain.dnssec?
      "<span class='soa-#{attr}'>#{value}</span>"
    }.join(' ').html_safe
  end
end
