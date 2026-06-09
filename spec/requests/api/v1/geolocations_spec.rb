require "rails_helper"

RSpec.describe "Api::V1::Geolocations", type: :request do
  let(:api_key) { create(:api_key) }
  let(:headers) { auth_headers(api_key) }
  let(:ip) { "134.201.250.155" }

  describe "GET /api/v1/geolocations" do
    let!(:geo1) { create(:geolocation, ip_address: "1.2.3.4") }
    let!(:geo2) { create(:geolocation, ip_address: "5.6.7.8") }

    context "with valid API key" do
      it "returns all geolocations" do
        get "/api/v1/geolocations", headers: headers
        expect(response).to have_http_status(:ok)
        expect(json_response[:data].length).to eq(2)
      end

      it "returns JSON:API formatted response" do
        get "/api/v1/geolocations", headers: headers
        data = json_response[:data].first
        expect(data).to include(:type, :id, :attributes)
        expect(data[:type]).to eq("geolocation")
      end
    end

    context "without API key" do
      it "returns 401" do
        get "/api/v1/geolocations"
        expect(response).to have_http_status(:unauthorized)
        expect(json_response[:errors].first[:status]).to eq("401")
      end
    end

    context "with inactive API key" do
      let(:api_key) { create(:api_key, :inactive) }

      it "returns 401" do
        get "/api/v1/geolocations", headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/geolocations/:ip_address" do
    let!(:geolocation) { create(:geolocation, ip_address: ip, country_name: "United States") }

    context "with valid API key" do
      it "returns the geolocation" do
        get "/api/v1/geolocations/#{ip}", headers: headers
        expect(response).to have_http_status(:ok)
        attrs = json_response[:data][:attributes]
        expect(attrs[:ip_address]).to eq(ip)
        expect(attrs[:country_name]).to eq("United States")
      end
    end

    context "when IP is not found" do
      it "returns 404" do
        get "/api/v1/geolocations/9.9.9.9", headers: headers
        expect(response).to have_http_status(:not_found)
        expect(json_response[:errors].first[:status]).to eq("404")
      end
    end

    context "without API key" do
      it "returns 401" do
        get "/api/v1/geolocations/#{ip}"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/geolocations" do
    context "with a valid IP address" do
      before { ipstack_stub(ip: ip) }

      it "creates a geolocation and returns 201" do
        post "/api/v1/geolocations", params: { ip_or_url: ip }.to_json, headers: headers
        expect(response).to have_http_status(:created)
        attrs = json_response[:data][:attributes]
        expect(attrs[:ip_address]).to eq(ip)
        expect(attrs[:country_code]).to eq("US")
      end

      it "persists the geolocation" do
        expect {
          post "/api/v1/geolocations", params: { ip_or_url: ip }.to_json, headers: headers
        }.to change(Geolocation, :count).by(1)
      end
    end

    context "when the IP already exists" do
      let!(:existing) { create(:geolocation, ip_address: ip) }

      it "returns 200 without creating a duplicate" do
        expect {
          post "/api/v1/geolocations", params: { ip_or_url: ip }.to_json, headers: headers
        }.not_to change(Geolocation, :count)
        expect(response).to have_http_status(:ok)
      end
    end

    context "with a valid URL" do
      let(:url) { "example.com" }
      let(:resolved_ip) { "93.184.216.34" }

      before do
        allow(Resolv).to receive(:getaddress).with("example.com").and_return(resolved_ip)
        ipstack_stub(ip: resolved_ip)
      end

      it "resolves to IP, creates geolocation, and stores the URL" do
        post "/api/v1/geolocations", params: { ip_or_url: url }.to_json, headers: headers
        expect(response).to have_http_status(:created)
        attrs = json_response[:data][:attributes]
        expect(attrs[:ip_address]).to eq(resolved_ip)
        expect(attrs[:url]).to eq("http://#{url}")
      end
    end

    context "when ip_or_url param is missing" do
      it "returns 400" do
        post "/api/v1/geolocations", params: {}.to_json, headers: headers
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "when URL cannot be resolved" do
      it "returns 422" do
        allow(Resolv).to receive(:getaddress).and_raise(Resolv::ResolvError)
        post "/api/v1/geolocations", params: { ip_or_url: "nonexistent.invalid" }.to_json, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:errors].first[:detail]).to include("Cannot resolve hostname")
      end
    end

    context "when the provider returns an error" do
      before { ipstack_error_stub(ip: ip) }

      it "returns 422 with the provider error" do
        post "/api/v1/geolocations", params: { ip_or_url: ip }.to_json, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:errors].first[:status]).to eq("422")
      end
    end

    context "without API key" do
      it "returns 401" do
        post "/api/v1/geolocations", params: { ip_or_url: ip }.to_json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /api/v1/geolocations/:ip_address" do
    let!(:geolocation) { create(:geolocation, ip_address: ip) }

    context "with valid API key" do
      it "deletes the geolocation and returns 204" do
        expect {
          delete "/api/v1/geolocations/#{ip}", headers: headers
        }.to change(Geolocation, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end
    end

    context "when IP is not found" do
      it "returns 404" do
        delete "/api/v1/geolocations/9.9.9.9", headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "without API key" do
      it "returns 401" do
        delete "/api/v1/geolocations/#{ip}"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
