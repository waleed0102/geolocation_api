if Rails.env.production?
  %w[IPSTACK_ACCESS_KEY].each do |var|
    raise "Missing required environment variable: #{var}. See .env.example." if ENV[var].blank?
  end
end
