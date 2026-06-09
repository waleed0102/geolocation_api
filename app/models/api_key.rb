class ApiKey < ApplicationRecord
  before_validation :generate_token, on: :create

  validates :name, presence: true
  validates :token, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }

  private

  def generate_token
    self.token = SecureRandom.hex(32)
  end
end
