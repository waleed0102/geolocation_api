require "rails_helper"

RSpec.describe GeolocationLookupService do
  let(:ip) { "134.201.250.155" }
  let(:mock_provider) { instance_double(GeolocationProviders::Ipstack) }
  let(:provider_data) do
    {
      continent_code: "NA", continent_name: "North America",
      country_code: "US", country_name: "United States",
      region_code: "CA", region_name: "California",
      city: "Los Angeles", zip: "90001",
      latitude: 34.0522, longitude: -118.2437,
      raw_data: { "ip" => ip }
    }
  end

  before do
    stub_const("GeolocationLookupService::PROVIDER_CLASS", GeolocationProviders::Ipstack)
    allow(GeolocationProviders::Ipstack).to receive(:new).and_return(mock_provider)
  end

  describe ".call" do
    context "when given a valid IP address" do
      before do
        allow(mock_provider).to receive(:fetch).with(ip)
          .and_return(GeolocationProviders::Result.success(provider_data))
      end

      it "creates and returns a geolocation" do
        result = described_class.call(ip)
        expect(result).to be_success
        expect(result.geolocation.ip_address).to eq(ip)
        expect(result.geolocation.country_code).to eq("US")
      end

      it "persists the geolocation to the database" do
        expect { described_class.call(ip) }.to change(Geolocation, :count).by(1)
      end
    end

    context "when the IP is already in the database" do
      let!(:existing) { create(:geolocation, ip_address: ip) }

      it "returns the existing record without calling the provider" do
        expect(mock_provider).not_to receive(:fetch)
        result = described_class.call(ip)
        expect(result).to be_success
        expect(result.geolocation).to eq(existing)
      end
    end

    context "when given a URL" do
      let(:url) { "example.com" }
      let(:resolved_ip) { "93.184.216.34" }

      before do
        allow(Resolv).to receive(:getaddress).with("example.com").and_return(resolved_ip)
        allow(mock_provider).to receive(:fetch).with(resolved_ip)
          .and_return(GeolocationProviders::Result.success(provider_data.merge(raw_data: { "ip" => resolved_ip })))
      end

      it "resolves the URL to an IP and stores the original URL" do
        result = described_class.call(url)
        expect(result).to be_success
        expect(result.geolocation.ip_address).to eq(resolved_ip)
        expect(result.geolocation.url).to eq("http://example.com")
      end
    end

    context "when the URL cannot be resolved" do
      before do
        allow(Resolv).to receive(:getaddress).and_raise(Resolv::ResolvError, "hostname not found")
      end

      it "returns a failure result" do
        result = described_class.call("nonexistent.invalid")
        expect(result).to be_failure
        expect(result.error).to include("Cannot resolve hostname")
      end
    end

    context "when given a private IP address" do
      it "rejects loopback addresses" do
        result = described_class.call("127.0.0.1")
        expect(result).to be_failure
        expect(result.error).to include("Private and reserved IP")
      end

      it "rejects RFC-1918 addresses" do
        result = described_class.call("192.168.1.1")
        expect(result).to be_failure
        expect(result.error).to include("Private and reserved IP")
      end

      it "rejects link-local addresses" do
        result = described_class.call("169.254.1.1")
        expect(result).to be_failure
        expect(result.error).to include("Private and reserved IP")
      end
    end

    context "when a concurrent insert causes RecordNotUnique" do
      let!(:concurrent_record) { create(:geolocation, ip_address: ip) }

      before do
        allow(mock_provider).to receive(:fetch).with(ip)
          .and_return(GeolocationProviders::Result.success(provider_data))
        # Simulate: initial find_by sees nothing (race begins), create! hits unique constraint
        allow(Geolocation).to receive(:find_by).with(ip_address: ip).and_return(nil)
        allow(Geolocation).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique)
        allow(Geolocation).to receive(:find_by!).with(ip_address: ip).and_return(concurrent_record)
      end

      it "returns the concurrently-inserted record without raising" do
        result = described_class.call(ip)
        expect(result).to be_success
        expect(result.geolocation).to eq(concurrent_record)
      end
    end

    context "when the provider fails" do
      before do
        allow(mock_provider).to receive(:fetch).with(ip)
          .and_return(GeolocationProviders::Result.failure("Provider error"))
      end

      it "returns a failure result" do
        result = described_class.call(ip)
        expect(result).to be_failure
        expect(result.error).to eq("Provider error")
      end
    end
  end
end
