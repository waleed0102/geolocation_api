Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allowed_origins = if Rails.env.development?
    [ "*" ]
  else
    ENV.fetch("CORS_ORIGINS", "").split(",").map(&:strip).reject(&:empty?)
  end

  unless allowed_origins.empty?
    allow do
      origins(*allowed_origins)
      resource "*", headers: :any, methods: %i[get post delete options head]
    end
  end
end
