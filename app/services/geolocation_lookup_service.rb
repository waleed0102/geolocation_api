require "resolv"
require "uri"
require "ipaddr"

class GeolocationLookupService
  # Swap this constant to change the geolocation provider globally.
  PROVIDER_CLASS = GeolocationProviders::Ipstack

  ServiceResult = Struct.new(:geolocation, :error, keyword_init: true) do
    def success? = error.nil?
    def failure? = !success?
  end

  def self.call(ip_or_url)
    new.call(ip_or_url)
  end

  def call(ip_or_url)
    ip_address = resolve_ip(ip_or_url)
    original_url = url_input?(ip_or_url) ? normalize_url(ip_or_url) : nil

    existing = Geolocation.find_by(ip_address: ip_address)
    return ServiceResult.new(geolocation: existing) if existing

    provider_result = provider.fetch(ip_address)
    return ServiceResult.new(error: provider_result.error) if provider_result.failure?

    geolocation = Geolocation.create!(
      provider_result.data.merge(ip_address: ip_address, url: original_url)
    )

    ServiceResult.new(geolocation: geolocation)
  rescue ArgumentError => e
    ServiceResult.new(error: e.message)
  rescue ActiveRecord::RecordInvalid => e
    ServiceResult.new(error: e.record.errors.full_messages.join(", "))
  end

  private

  def provider
    @provider ||= PROVIDER_CLASS.new
  end

  def resolve_ip(input)
    return input if ip_address?(input)

    hostname = extract_hostname(input)
    Resolv.getaddress(hostname)
  rescue Resolv::ResolvError
    raise ArgumentError, "Cannot resolve hostname: #{extract_hostname(input)}"
  end

  def ip_address?(input)
    IPAddr.new(input)
    true
  rescue IPAddr::InvalidAddressError, IPAddr::AddressFamilyError
    false
  end

  def url_input?(input)
    !ip_address?(input)
  end

  def extract_hostname(input)
    input = "http://#{input}" unless input.start_with?("http://", "https://")
    URI.parse(input).host || input
  rescue URI::InvalidURIError
    input
  end

  def normalize_url(input)
    return input if input.start_with?("http://", "https://")
    "http://#{input}"
  end
end
