require "rails_helper"

RSpec.describe ApiKey, type: :model do
  describe "token generation" do
    it "exposes a raw token after create" do
      key = create(:api_key)
      expect(key.raw_token).to be_present
      expect(key.raw_token.length).to eq(64)
    end

    it "stores a digest, not the raw token" do
      key = create(:api_key)
      expect(key.token_digest).to be_present
      expect(key.token_digest).not_to eq(key.raw_token)
    end

    it "generates unique tokens" do
      key1 = create(:api_key)
      key2 = create(:api_key)
      expect(key1.raw_token).not_to eq(key2.raw_token)
    end
  end

  describe ".find_by_token" do
    it "returns the active key matching the raw token" do
      key = create(:api_key)
      expect(ApiKey.find_by_token(key.raw_token)).to eq(key)
    end

    it "returns nil for a wrong token" do
      create(:api_key)
      expect(ApiKey.find_by_token("wrongtoken")).to be_nil
    end

    it "returns nil for a blank token" do
      expect(ApiKey.find_by_token(nil)).to be_nil
      expect(ApiKey.find_by_token("")).to be_nil
    end

    it "does not return inactive keys" do
      key = create(:api_key, :inactive)
      expect(ApiKey.find_by_token(key.raw_token)).to be_nil
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
