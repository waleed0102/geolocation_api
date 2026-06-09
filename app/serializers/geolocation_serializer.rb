class GeolocationSerializer
  include JSONAPI::Serializer

  set_type :geolocation

  attributes :ip_address, :url, :continent_code, :continent_name,
             :country_code, :country_name, :region_code, :region_name,
             :city, :zip, :latitude, :longitude

  attribute :created_at do |object|
    object.created_at.iso8601
  end
end
