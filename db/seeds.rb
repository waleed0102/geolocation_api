key = ApiKey.find_or_initialize_by(name: "default")

if key.new_record?
  key.active = true
  key.save!
  puts "API key '#{key.name}': #{key.raw_token}"
  puts "Use this in requests:  Authorization: Bearer #{key.raw_token}"
else
  puts "API key '#{key.name}' already exists (raw token was shown at creation time)."
  puts "To rotate: rails runner \"ApiKey.find_by(name: 'default').destroy\" && rails db:seed"
end
