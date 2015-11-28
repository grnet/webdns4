require 'ipaddr'
require 'socket'

class Ipv6Validator < ActiveModel::EachValidator
  # Returns true if addr is valid IPv6 address.
  def valid_v6?(addr)
    return false if addr['/'] # IPAddr accepts addr/mask format
    return false if addr['[']
    return false if addr[']']
    IPAddr.new(addr, Socket::AF_INET6)
    true
  rescue IPAddr::AddressFamilyError, IPAddr::InvalidAddressError
    false
  end

  # Add an attribute error if this is not a valid IPv4 address.
  def validate_each(record, attribute, value)
    return if valid_v6?(value)

    record.errors[attribute] << 'is not a valid IPv6 address'
  end
end
