key = ApiKey.find_or_create_by!(name: "default") do |k|
  k.active = true
end

puts "API key '#{key.name}': #{key.token}"
puts "Use this in requests:  Authorization: Bearer #{key.token}"
