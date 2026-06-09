require "rails_helper"

RSpec.describe Geolocation, type: :model do
  describe "validations" do
    it "is valid with a valid IPv4 address" do
      expect(build(:geolocation, ip_address: "134.201.250.155")).to be_valid
    end

    it "is valid with a valid IPv6 address" do
      expect(build(:geolocation, ip_address: "2001:0db8:85a3:0000:0000:8a2e:0370:7334")).to be_valid
    end

    it "requires ip_address" do
      expect(build(:geolocation, ip_address: nil)).not_to be_valid
    end

    it "rejects invalid IP formats" do
      expect(build(:geolocation, ip_address: "not-an-ip")).not_to be_valid
      expect(build(:geolocation, ip_address: "999.999.999.999")).not_to be_valid
      expect(build(:geolocation, ip_address: "example.com")).not_to be_valid
    end

    it "enforces uniqueness on ip_address" do
      create(:geolocation, ip_address: "1.2.3.4")
      expect(build(:geolocation, ip_address: "1.2.3.4")).not_to be_valid
    end
  end
end
