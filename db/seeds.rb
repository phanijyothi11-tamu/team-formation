# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end



# Create a form response
FormResponse.create!(
  form: Form.find(30),
  student: Student.find(1),
  responses: {}.to_json
)
FormResponse.create!(
  form: Form.find(30),
  student: Student.find(2),
  responses: {}.to_json
)
puts "New seed data created successfully!"

# Assuming FactoryBot is available, adjust to your current setup

# Create a form and add a gender attribute with options
form = Form.create!(name: "Team Formation Form", description: "Form for collecting team preferences", user_id: 1)
gender_attr = form.form_attributes.create!(name: "Gender", field_type: "mcq", options: "Male,Female,Other")

# Create 12 students with gender-diverse responses
students = []
12.times do |i|
  student = Student.create!(name: "Student#{i + 1}", email: "student#{i + 1}@example.com", uin: "12345678#{i}", section: "A")
  gender = i < 4 ? "feamle" : i < 8 ? "male" : i < 10 ? "other" : "prefer not to say"
  FormResponse.create!(form: form, student: student, responses: { gender_attr.id => gender })
  students << student
end

puts "Seeded 12 students with diverse gender responses."
