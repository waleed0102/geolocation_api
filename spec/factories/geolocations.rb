FactoryBot.define do
  factory :geolocation do
    sequence(:ip_address) { |n| "10.0.#{n / 256}.#{n % 256}" }
    url { nil }
    continent_code { "NA" }
    continent_name { "North America" }
    country_code { "US" }
    country_name { "United States" }
    region_code { "CA" }
    region_name { "California" }
    city { "Los Angeles" }
    zip { "90001" }
    latitude { 34.0522 }
    longitude { -118.2437 }
    raw_data { {} }
  end
end
