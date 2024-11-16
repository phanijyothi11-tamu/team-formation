Given("I am logged in as the professor") do
  @user = User.create!(email: "user@example.com", name: "Professor", uin: "12345")
  page.set_rack_session(user_id: @user.id)
end

Given("I have created a form with attributes") do
  @form = Form.create!(name: "Test Form", description: "Test Description", user: @user)
  @form.form_attributes.create!(name: "Question 1", field_type: "text_input")
end

When("I visit the edit page for form") do
  visit edit_form_path(@form)
end

Then("I should see a link to duplicate the form") do
  expect(page).to have_link("Duplicate Form")
end

When("I click the {string}") do |link_text|
  click_link link_text
end

Then("I should be redirected to the edit page for the duplicated form without redirecting to new tab") do
  expect(current_path).to eq(edit_form_path(Form.last))  # Assuming the last form is the duplicated one
end

Then("the new form should have the name {string}") do |expected_name|
  expect(Form.last.name).to eq(expected_name)
end