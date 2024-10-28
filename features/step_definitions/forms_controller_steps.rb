Given("I am logged in as a valid user with a form created") do
  # Create a new user in the database
  @user = User.create!(name: "Professor", email: "professor@example.com", uin: "123456789")
  # Create a new form in the database
  @form = Form.create!(name: "My Form", description: "This is my form", user_id: @user.id)
  # Simulate a logged-in session for this user
  page.set_rack_session(user_id: @user.id)
end

Given("I am on the upload page") do
  visit upload_form_path(@form)
end

When("I submit the upload form without a file") do
  click_button "upload_button"
end

When("I submit the upload form") do
  click_button "upload_button"
end

When("I have uploaded a file with an empty first row") do
  file_path = Rails.root.join("spec/fixtures/files/empty_header.csv")
  attach_file("file", file_path)
end

When("I have uploaded a file without 'Name', 'UIN', and 'Email ID' columns") do
  file_path = Rails.root.join("spec/fixtures/files/missing_columns.csv")
  attach_file("file", file_path)
end

When("I have uploaded a file with missing name in a row") do
  file_path = Rails.root.join("spec/fixtures/files/missing_name.csv")
  attach_file("file", file_path)
end

When("I have uploaded a file with an invalid UIN in a row") do
  file_path = Rails.root.join("spec/fixtures/files/invalid_uin.csv")
  attach_file("file", file_path)
end

When("I have uploaded a file with missing email in a row") do
  file_path = Rails.root.join("spec/fixtures/files/missing_email.csv")
  attach_file("file", file_path)
end

When("I have uploaded a file with an invalid email format in a row") do
  file_path = Rails.root.join("spec/fixtures/files/invalid_email.csv")
  attach_file("file", file_path)
end

When("I have uploaded a valid file") do
  file_path = Rails.root.join("spec/fixtures/files/valid_file.csv")
  attach_file("file", file_path)
end

Then("I should be redirected to my user profile page") do
  expect(page.current_path).to eq(edit_form_path(@form))
end
