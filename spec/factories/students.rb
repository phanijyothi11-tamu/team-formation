FactoryBot.define do
  factory :student do
    sequence(:uin) { |n| "1000#{n.to_s.rjust(5, '0')}" }
    sequence(:name) { |n| "Student #{n}" }
    sequence(:email) { |n| "student#{n}@example.com" }
    section { [ 'A', 'B', 'C' ].sample }

    trait :with_form_responses do
      after(:create) do |student|
        create_list(:form_response, 3, student: student)
      end
    end
  end
end


