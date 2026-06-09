class Geolocation < ApplicationRecord
  before_validation :normalize_ip_address, if: -> { ip_address.present? }

  validates :ip_address, presence: true, uniqueness: { case_sensitive: false }
  validate :ip_address_format, if: -> { ip_address.present? }

  private

  def normalize_ip_address
    self.ip_address = IPAddr.new(ip_address).to_s
  rescue IPAddr::InvalidAddressError, IPAddr::AddressFamilyError
    nil # leave as-is; ip_address_format validation will catch it
  end

  def ip_address_format
    IPAddr.new(ip_address)
  rescue IPAddr::InvalidAddressError, IPAddr::AddressFamilyError
    errors.add(:ip_address, "must be a valid IPv4 or IPv6 address")
  end
end
