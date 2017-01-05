class NotIpValidator < ActiveModel::EachValidator
  # Add an Atribute error if this a valid IP address.
  def validate_each(record, attribute, value)
    if [Ipv4Validator, Ipv6Validator].any? { |fam| fam.valid?(value) }
      record.errors[attribute] << 'should not be an IP address'
    end
  end
end
