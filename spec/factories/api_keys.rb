FactoryBot.define do
  factory :api_key do
    name { Faker::App.name }
    active { true }

    trait :inactive do
      active { false }
    end
  end
end
