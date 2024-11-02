FactoryBot.define do
  factory :team do
    association :form
    name { "Team #{Faker::Number.unique.between(from: 1, to: 100)}" }
    section { "Section #{[ 'A', 'B', 'C' ].sample}" }

    # Define a members array with mock data for each member
    members do
      Array.new(3) do |i|
        {
          "id" => Faker::Number.unique.number(digits: 4),
          "name" => Faker::Name.name,
          "uin" => Faker::Number.number(digits: 9),
          "email" => Faker::Internet.email
        }
      end
    end
  end
end
