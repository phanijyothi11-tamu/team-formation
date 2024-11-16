# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end



# # Create a form response
# FormResponse.create!(
#   form: Form.find(30),
#   student: Student.find(1),
#   responses: {}.to_json
# )
# FormResponse.create!(
#   form: Form.find(30),
#   student: Student.find(2),
#   responses: {}.to_json
# )

Form.destroy_all
Student.destroy_all
FormResponse.destroy_all
User.destroy_all

# # Create a user ("required for form creation")
user = User.create!(
  email: "sahithi@tamu.edu",
  uin: "123456789",
  name: "Professor Test"
)

# Create a form
form = Form.create!(
  name: "Team Formation Form",
  description: "This form is used to gather information for team formation.",
  deadline: 1.week.from_now,
  user: user,
  published: true
)

# Create form attributes
gender_attr = form.form_attributes.create!(
  name: "Gender",
  field_type: "mcq",
  options: "Male,Female,Other",
  weightage: 1
)

ethnicity_attr = form.form_attributes.create!(
  name: "Ethnicity",
  field_type: "mcq",
  options: "Asian,African,European,Hispanic,Other",
  weightage: 1
)

skill_attr = form.form_attributes.create!(
  name: "Skill Level",
  field_type: "scale",
  min_value: 1,
  max_value: 10,
  weightage: 1
)

# Create students and their responses
30.times do |i|
  student = Student.create!(
    uin: "10000#{i.to_s.rjust(3, '0')}",
    name: "Student #{i + 1}",
    email: "student#{i + 1}@example.com",
    section: [ 'A', 'B' ].sample
  )

  FormResponse.create!(
    form: form,
    student: student,
    responses: {
      gender_attr.name => gender_attr.options.split(',').sample,
      ethnicity_attr.name => ethnicity_attr.options.split(',').sample,
      skill_attr.name => rand(skill_attr.min_value..skill_attr.max_value)
    }.to_json
  )
end

puts "Seed data created successfully!"
puts "Form ID: #{form.id}"
puts "Total students created: #{Student.count}"
puts "Total form responses: #{FormResponse.count}"
