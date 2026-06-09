class ApiKey < ApplicationRecord
  attr_reader :raw_token

  before_validation :generate_token, on: :create

  validates :name, presence: true
  validates :token_digest, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }

  def self.find_by_token(raw)
    return nil if raw.blank?
    active.find_by(token_digest: digest(raw))
  end

  def self.digest(raw)
    OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, raw)
  end

  private

  def generate_token
    @raw_token = SecureRandom.hex(32)
    self.token_digest = self.class.digest(@raw_token)
  end
end
