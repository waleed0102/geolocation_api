module GeolocationProviders
  class Base
    # Fetches geolocation data for the given IP address.
    # Returns a GeolocationProviders::Result.
    def fetch(ip_address)
      raise NotImplementedError, "#{self.class} must implement #fetch"
    end
  end
end
