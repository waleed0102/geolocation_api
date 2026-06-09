require "rails_helper"

RSpec.describe ApiKey, type: :model do
  describe "token generation" do
    it "generates a token before create" do
      key = create(:api_key)
      expect(key.token).to be_present
      expect(key.token.length).to eq(64)
    end

    it "generates unique tokens" do
      key1 = create(:api_key)
      key2 = create(:api_key)
      expect(key1.token).not_to eq(key2.token)
    end
  end

  describe "scopes" do
    it ".active returns only active keys" do
      active = create(:api_key, active: true)
      create(:api_key, active: false)
      expect(ApiKey.active).to contain_exactly(active)
    end
  end

  describe "validations" do
    it "requires a name" do
      expect(build(:api_key, name: nil)).not_to be_valid
    end
  end
end
