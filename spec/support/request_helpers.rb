module RequestHelpers
  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  def auth_headers(api_key)
    { "Authorization" => "Bearer #{api_key.raw_token}", "Content-Type" => "application/json" }
  end

  def ipstack_stub(ip:, status: 200, body: nil)
    stub_request(:get, "http://api.ipstack.com/#{ip}")
      .with(query: hash_including("access_key" => anything))
      .to_return(status: status, body: (body || ipstack_success_body(ip)).to_json, headers: { "Content-Type" => "application/json" })
  end

  def ipstack_error_stub(ip:, code: 101, info: "Invalid API key")
    stub_request(:get, "http://api.ipstack.com/#{ip}")
      .with(query: hash_including("access_key" => anything))
      .to_return(
        status: 200,
        body: { success: false, error: { code: code, type: "invalid_access_key", info: info } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def ipstack_success_body(ip)
    {
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
    }
  end
end
