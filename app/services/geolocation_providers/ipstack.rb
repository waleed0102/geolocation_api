require "faraday"
require "json"

module GeolocationProviders
  class Ipstack < Base
    BASE_URL = "http://api.ipstack.com"

    def fetch(ip_address)
      response = connection.get("/#{ip_address}", access_key: api_key)

      unless response.success?
        return Result.failure("Provider returned HTTP #{response.status}")
      end

      data = JSON.parse(response.body)

      if data["success"] == false
        code = data.dig("error", "code")
        info = data.dig("error", "info") || "Unknown provider error"
        Result.failure("[#{code}] #{info}")
      else
        Result.success(map_response(data))
      end
    rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
      Result.failure("Provider unreachable: #{e.message}")
    rescue JSON::ParserError
      Result.failure("Invalid response from provider")
    end

    private

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |f|
        f.options.timeout = 5
        f.options.open_timeout = 3
        f.adapter Faraday.default_adapter
      end
    end

    def api_key
      ENV["IPSTACK_ACCESS_KEY"].presence ||
        raise(ArgumentError, "IPSTACK_ACCESS_KEY environment variable is not set")
    end

    def map_response(data)
      {
        continent_code: data["continent_code"],
        continent_name: data["continent_name"],
        country_code: data["country_code"],
        country_name: data["country_name"],
        region_code: data["region_code"],
        region_name: data["region_name"],
        city: data["city"],
        zip: data["zip"],
        latitude: data["latitude"],
        longitude: data["longitude"],
        raw_data: data
      }
    end
  end
end
