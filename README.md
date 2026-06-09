# Geolocation API

A RESTful JSON:API-compliant Rails service that stores and retrieves geolocation data by IP address or URL, backed by [ipstack](https://ipstack.com/).

## Features

- Look up geolocation by IPv4, IPv6, or domain name/URL
- Cached results — a resolved IP is only fetched from the provider once
- Provider-agnostic design — swap `GeolocationLookupService::PROVIDER_CLASS` to change provider
- JSON:API response format
- API key authentication on all endpoints

## Quick Start (Docker)

```bash
cp .env.example .env
# Edit .env and set IPSTACK_ACCESS_KEY

docker compose up
```

The API will be available at `http://localhost:3000`. On first boot it runs migrations and seeds a default API key — grab it from the container logs:

```
web-1  | API key 'default': abc123...
```

## Local Setup (without Docker)

**Requirements:** Ruby 3.4.4, PostgreSQL 14+

```bash
cp .env.example .env
# Set IPSTACK_ACCESS_KEY in .env

bundle install
bundle exec rails db:create db:migrate db:seed
bundle exec rails server -p 3000
```

## Authentication

All endpoints require an API key in the `Authorization` header:

```
Authorization: Bearer <your_api_key>
```

Generate a key via the Rails console:

```ruby
key = ApiKey.create!(name: "my-client")
puts key.token
```

## API Reference

All responses follow the [JSON:API](https://jsonapi.org/) specification.

### List all geolocations

```
GET /api/v1/geolocations
```

```bash
curl http://localhost:3000/api/v1/geolocations \
  -H "Authorization: Bearer <token>"
```

### Get geolocation by IP

```
GET /api/v1/geolocations/:ip_address
```

```bash
curl http://localhost:3000/api/v1/geolocations/134.201.250.155 \
  -H "Authorization: Bearer <token>"
```

### Add geolocation (by IP or URL)

```
POST /api/v1/geolocations
Content-Type: application/json
```

```bash
# By IP address
curl -X POST http://localhost:3000/api/v1/geolocations \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"ip_or_url": "134.201.250.155"}'

# By URL
curl -X POST http://localhost:3000/api/v1/geolocations \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"ip_or_url": "example.com"}'
```

Returns `201 Created` for new records, `200 OK` for already-stored IPs.

### Delete geolocation

```
DELETE /api/v1/geolocations/:ip_address
```

```bash
curl -X DELETE http://localhost:3000/api/v1/geolocations/134.201.250.155 \
  -H "Authorization: Bearer <token>"
```

Returns `204 No Content`.

### Error responses

```json
{
  "errors": [
    {
      "status": "422",
      "title": "Unprocessable Entity",
      "detail": "Cannot resolve hostname: bad.invalid"
    }
  ]
}
```

| Status | Meaning |
|--------|---------|
| 400 | Missing required parameter |
| 401 | Missing or invalid API key |
| 404 | IP address not found in the database |
| 422 | Cannot resolve URL or provider returned an error |

## Swapping the Geolocation Provider

Edit `app/services/geolocation_lookup_service.rb` and change the constant:

```ruby
PROVIDER_CLASS = GeolocationProviders::MyNewProvider
```

Implement the new provider by inheriting `GeolocationProviders::Base` and defining `#fetch(ip_address) → GeolocationProviders::Result`.

## Running Tests

```bash
bundle exec rspec
```

The test suite uses WebMock to stub all external HTTP calls — no real ipstack key required.

## Project Structure

```
app/
  controllers/api/v1/geolocations_controller.rb  # REST endpoints
  models/
    geolocation.rb                               # IP + geolocation data
    api_key.rb                                   # Authentication tokens
  serializers/geolocation_serializer.rb          # JSON:API output
  services/
    geolocation_lookup_service.rb                # Orchestration: resolve, cache, fetch
    geolocation_providers/
      base.rb                                    # Provider contract
      ipstack.rb                                 # ipstack.com implementation
      result.rb                                  # Success/failure value object
spec/
  models/                                        # Model validations
  services/                                      # Unit tests with stubbed HTTP
  requests/api/v1/                               # Full request/response integration tests
```
