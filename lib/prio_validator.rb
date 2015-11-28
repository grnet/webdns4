# Validates DNS priorities [0, 65535]
class PrioValidator < ActiveModel::EachValidator
  # Adds an attribute error if value is not a valid DNS priority.
  def validate_each(record, attribute, value)
    # Rails autocasts integer fields to 0 if a non-numerical value is passed
    # we override that by using th *_before_type_cast helper method
    before_cast = :"#{attribute}_before_type_cast"
    raw_value = record.send(before_cast) if record.respond_to?(before_cast)
    raw_value ||= value

    val = Integer(raw_value)
    if val < 0 || val > 65_535
      record.errors[attribute] << 'is not a valid DNS priority [0, 65535]'
    end

  rescue ArgumentError, TypeError
    record.errors[attribute] << 'is not a valid DNS priority [0, 65535]'
  end
end
