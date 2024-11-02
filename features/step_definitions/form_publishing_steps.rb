Given("students with IDs 1 and 2 have access to the form") do
  # Ensure students exist
  student1 = Student.find_by(id: 1) || create(:student, id: 1, name: "Student One", email: "student1@example.com", uin: "111111111")
  student2 = Student.find_by(id: 2) || create(:student, id: 2, name: "Student Two", email: "student2@example.com", uin: "222222222")

  # Associate students with the form with empty JSON responses
  create(:form_response, form: @form, student: student1)
  create(:form_response, form: @form, student: student2)
end

Given("the deadline is set") do
  @form.update!(deadline: 1.day.from_now)
end

Given("I have a form that is closed") do
    step "I have created a form that is published"
    step "I navigate to my user profile page"
    step "I click on \"View\" for that form"
    step "I click \"Close Form\""
    step "The form should be closed"
end

Then("The student with ID {int} can access the form") do |id|
  visit student_path(id)
  expect(page).to have_content(@form.name)
  expect(page).to have_link("View/Respond to Form")
end

Then("The student with ID {int} cannot access the form") do |id|
  visit student_path(id)
  expect(page).not_to have_content(@form.name)
  expect(page).not_to have_link("View/Respond to Form")
end

Then("The students with IDs {int} and {int} can access the form") do |id1, id2|
  step "The student with ID #{id1} can access the form"
  step "The student with ID #{id2} can access the form"
end

Then("The students with IDs {int} and {int} cannot access the form") do |id1, id2|
  step "The student with ID #{id1} cannot access the form"
  step "The student with ID #{id2} cannot access the form"
end

Then("The form should be published") do
  @form.reload  # Reload the form to get the latest database state
  expect(@form.published).to be true
end

Then("The form should be closed") do
  @form.reload  # Reload the form to get the latest database state
  expect(@form.published).to be false
end
