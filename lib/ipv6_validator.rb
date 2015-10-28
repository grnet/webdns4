require 'ipaddr'
require 'socket'

class Ipv6Validator < ActiveModel::EachValidator

  def valid_v6?(addr)
    return false if addr['/'] # IPAddr accepts addr/mask format
    return false if addr['[']
    return false if addr[']']
    IPAddr.new(addr, Socket::AF_INET6)
    true
  rescue IPAddr::AddressFamilyError, IPAddr::InvalidAddressError
    false
  end

  def validate_each(record, attribute, value)
    return if valid_v6?(value)

    record.errors[attribute] << 'is not a valid IPv6 address'
  end
end
