class Geolocation < ApplicationRecord
  validates :ip_address, presence: true, uniqueness: { case_sensitive: false }
  validate :ip_address_format, if: -> { ip_address.present? }

  scope :active, -> { all }

  private

  def ip_address_format
    IPAddr.new(ip_address)
  rescue IPAddr::InvalidAddressError, IPAddr::AddressFamilyError
    errors.add(:ip_address, "must be a valid IPv4 or IPv6 address")
  end
end
