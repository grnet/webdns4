require 'ipaddr'
require 'socket'

class Ipv4Validator < ActiveModel::EachValidator
  # Returns true if addr is a valid IPv4 address.
  def valid_v4?(addr)
    return false if addr['/'] # IPAddr accepts addr/mask format
    IPAddr.new(addr, Socket::AF_INET)
    true
  rescue IPAddr::AddressFamilyError, IPAddr::InvalidAddressError
    false
  end

  # Add an attribute error if this is not a valid IPv4 address.
  def validate_each(record, attribute, value)
    return if valid_v4?(value)
    record.errors[attribute] << 'is not a valid IPv4 address'
  end
end
