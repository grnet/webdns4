require 'ipaddr'
require 'socket'

class Ipv4Validator < ActiveModel::EachValidator
  def valid_v4?(addr)
    return false if addr['/'] # IPAddr accepts addr/mask format
    IPAddr.new(addr, Socket::AF_INET)
    true
  rescue IPAddr::AddressFamilyError, IPAddr::InvalidAddressError
    false
  end

  def validate_each(record, attribute, value)
    return if valid_v4?(value)
    record.errors[attribute] << 'is not a valid IPv4 address'
  end
end
