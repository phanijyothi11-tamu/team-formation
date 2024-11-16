# This step creates a form associated with the current user
Given("I have created a form") do
  @form = Form.create!(name: "Test Form", description: "Test Description", user: @user)
end

# This step navigates to the edit page of the previously created form
When("I visit the edit page for the form") do
  visit edit_form_path(@form)
end

# This step checks if there's an option to add a new attribute on the page
Then("I should see an option to add a new attribute") do
  expect(page).to have_content("Add Attribute")
end

# This step fills in the attribute name field
When("I enter {string} as the attribute name") do |attribute_name|
  fill_in "Attribute Name", with: attribute_name
end

# This step selects the attribute type from a dropdown
When("I select {string} as the attribute type") do |attribute_type|
  select attribute_type, from: "attribute_type"
end

# This step fills in the minimum value for a scale attribute
# It also waits for the field to become visible (important for JavaScript-driven forms)
When("I enter {string} as the minimum value") do |min_value|
  # Find the field regardless of visibility
  min_field = page.find('#attribute_min_value', visible: :all)
  min_field.set(min_value)
end

# This step fills in the maximum value for a scale attribute
# It also waits for the field to become visible (important for JavaScript-driven forms)
When("I enter {string} as the maximum value") do |max_value|
  max_field = page.find('#attribute_max_value', visible: :all)
  max_field.set(max_value)
end

# This step submits the new attribute form
When("I submit the new attribute") do
  click_button "Save Attribute"
end

# This step checks if the newly added attribute is listed on the form
Then("I should see {string} listed as an attribute on the form") do |attribute_name|
  expect(page).to have_content(attribute_name)
end

# This step checks for a success message after adding an attribute
Then("I should see a success message") do
  expect(page).to have_content("Attribute was successfully added to the form.")
end

# This step verifies that the attribute is saved in the database
Then("the attribute {string} should be saved in the database") do |attribute_name|
  @form.reload  # Ensure we have the latest data from the database
  attribute = @form.form_attributes.find_by(name: attribute_name)
  expect(attribute).to be_present, "Attribute '#{attribute_name}' was not found in the database"
end

# This step checks if a scale attribute has the correct min and max values in the database
Then("the attribute {string} should have a scale from {int} to {int}") do |attribute_name, min, max|
  @form.reload  # Ensure we have the latest data from the database
  attribute = @form.form_attributes.find_by(name: attribute_name)
  expect(attribute).to be_present, "Attribute '#{attribute_name}' was not found in the database"
  expect(attribute.field_type).to eq('scale'), "Attribute '#{attribute_name}' is not a scale type"
  expect(attribute.min_value).to eq(min), "Minimum value for '#{attribute_name}' is incorrect"
  expect(attribute.max_value).to eq(max), "Maximum value for '#{attribute_name}' is incorrect"
end

# This step creates an attribute associated with the current form
Given("I have created an attribute {string} with weightage {string}") do |attribute_name, weightage|
  @attribute = @form.form_attributes.create!(
    name: attribute_name,
    field_type: 'scale',
    min_value: 1,
    max_value: 10,
    weightage: weightage.to_f
  )
end

When("I enter {string} as the new weightage") do |weightage|
  @attribute ||= @form.form_attributes.last
  within("form[action='#{update_weightage_form_attribute_path(@form, @attribute)}']") do
    fill_in "attribute[weightage]", with: weightage
  end
end

When("I enter {string} as the new weightage for {string}") do |weightage, attribute_name|
  @attribute = @form.form_attributes.find_by(name: attribute_name)
  within("form[action='#{update_weightage_form_attribute_path(@form, @attribute)}']") do
    fill_in "attribute[weightage]", with: weightage
  end
end

# This step updates the weightage
When("I update the weightage") do
  within("form[action='#{update_weightage_form_attribute_path(@form, @attribute)}']") do
    click_button "Update Weightage"
  end
end

Then("I should see the weightage updated to {string}") do |weightage|
  @attribute.reload
  expect(@attribute.weightage).to eq(weightage.to_f)
  expect(page).to have_content("Weightage was successfully updated.")
end

Then("I should see an error message about exceeding total weightage") do
  expect(page).to have_content("Total weightage would be")
  expect(page).to have_content("Weightages should sum to 1")
end

Then("I should not see a weightage input field for the {string} attribute") do |attribute_name|
  expect(page).not_to have_field("Update Weightage (0.0 to 1.0)", wait: 5)
end

Then("the {string} attribute should be saved without a weightage value") do |attribute_name|
  attribute = @form.form_attributes.find_by(name: attribute_name)
  expect(attribute.weightage).to be_nil
end

Then("I should see {string} displayed for the weightage of {string} and {string} attributes") do |weightage_text, attr1, attr2|
  expect(page).to have_content("#{attr1}")
  expect(page).to have_content("#{attr2}")
  expect(page).to have_content("Current Weightage: #{weightage_text}")
end
