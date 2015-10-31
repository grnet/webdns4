module RecordsHelper

  def name_field_append(record)
    return ".#{record.domain.name}" if not record.domain.reverse?

    ".#{record.domain.name} (#{record.domain.subnet})"
  end
end
