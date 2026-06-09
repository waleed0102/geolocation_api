require "rails_helper"

RSpec.describe GeolocationProviders::Ipstack do
  subject(:provider) { described_class.new }

  let(:ip) { "134.201.250.155" }

  before { stub_const("ENV", ENV.to_h.merge("IPSTACK_ACCESS_KEY" => "test_key")) }

  describe "#fetch" do
    context "when the provider returns valid data" do
      before do
        stub_request(:get, "http://api.ipstack.com/#{ip}")
          .with(query: { access_key: "test_key" })
          .to_return(
            status: 200,
            body: {
              ip: ip,
              continent_code: "NA",
              continent_name: "North America",
              country_code: "US",
              country_name: "United States",
              region_code: "CA",
              region_name: "California",
              city: "Los Angeles",
              zip: "90001",
              latitude: 34.0522,
              longitude: -118.2437
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns a successful result" do
        result = provider.fetch(ip)
        expect(result).to be_success
      end

      it "maps all fields correctly" do
        data = provider.fetch(ip).data
        expect(data[:country_code]).to eq("US")
        expect(data[:country_name]).to eq("United States")
        expect(data[:city]).to eq("Los Angeles")
        expect(data[:latitude]).to eq(34.0522)
        expect(data[:longitude]).to eq(-118.2437)
      end

      it "includes raw_data" do
        data = provider.fetch(ip).data
        expect(data[:raw_data]).to include("ip" => ip)
      end
    end

    context "when the provider returns an API error" do
      before do
        stub_request(:get, "http://api.ipstack.com/#{ip}")
          .with(query: { access_key: "test_key" })
          .to_return(
            status: 200,
            body: {
              success: false,
              error: { code: 101, type: "invalid_access_key", info: "You have not supplied a valid API access key." }
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns a failure result" do
        result = provider.fetch(ip)
        expect(result).to be_failure
      end

      it "includes the error message" do
        result = provider.fetch(ip)
        expect(result.error).to include("valid API access key")
      end
    end

    context "when the provider returns HTTP 5xx" do
      before do
        stub_request(:get, "http://api.ipstack.com/#{ip}")
          .with(query: { access_key: "test_key" })
          .to_return(status: 503, body: "Service Unavailable", headers: {})
      end

      it "returns a failure result with the status code" do
        result = provider.fetch(ip)
        expect(result).to be_failure
        expect(result.error).to include("503")
      end
    end

    context "when the network is unreachable" do
      before do
        stub_request(:get, "http://api.ipstack.com/#{ip}")
          .with(query: { access_key: "test_key" })
          .to_raise(Faraday::ConnectionFailed.new("connection refused"))
      end

      it "returns a failure result" do
        result = provider.fetch(ip)
        expect(result).to be_failure
        expect(result.error).to include("Provider unreachable")
      end
    end

    context "when the response is not valid JSON" do
      before do
        stub_request(:get, "http://api.ipstack.com/#{ip}")
          .with(query: { access_key: "test_key" })
          .to_return(status: 200, body: "not json", headers: { "Content-Type" => "text/plain" })
      end

      it "returns a failure result" do
        result = provider.fetch(ip)
        expect(result).to be_failure
        expect(result.error).to include("Invalid response")
      end
    end

    context "when IPSTACK_ACCESS_KEY is not set" do
      before { stub_const("ENV", ENV.to_h.except("IPSTACK_ACCESS_KEY")) }

      it "raises ArgumentError caught by the service" do
        expect { provider.fetch(ip) }.to raise_error(ArgumentError, /IPSTACK_ACCESS_KEY/)
      end
    end
  end
end
