Given('there is a published form') do
    @form = FactoryBot.create(:form)
end

Given('there is a logged student') do
    @student = FactoryBot.create(:student)
end

Given('associated Form response') do
    @form_response = FactoryBot.create(:form_response, student: @student, responses: { "question1" => "dummy", "question2" => "dummy" }) # Create a form response for the student
end

When('I visit the form responses page for the specific form and student') do
    visit form_response_path(@form_response)
end

When('I fill in the form response') do
    @form = FactoryBot.create(:form)
    @student = FactoryBot.create(:student)
    @form_response = FactoryBot.create(:form_response, student: @student, responses: { "question1" => "dummy", "question2" => "dummy" }) # Create a form response for the student
    @form.form_attributes.each do |attribute|
      case attribute.field_type
      when 'text_input'
        fill_in "form_response[responses][#{attribute.id}]", with: "Some answer for #{attribute.name}"
      when 'mcq'
        if attribute.options.present?
          first_option = attribute.options.split(',').first.strip
          select first_option, from: "form_response[responses][#{attribute.id}]"
        end
      when 'scale'
        fill_in "form_response[responses][#{attribute.id}]", with: 5 # Example value for scale
      end
    end
end
# Given steps to ensure form and student responses exist and are accessible

Given('there is a published form with responses') do
  @form ||= FactoryBot.create(:form) # Create form if it doesn't exist
  @form_responses ||= FactoryBot.create_list(:form_response, 3, form: @form)
end

Given('there is a student with responses') do
  @student ||= FactoryBot.create(:student) # Create student if it doesn't exist
  @student_responses ||= FactoryBot.create_list(:form_response, 2, student: @student)
end

# Navigating to specific form or student form response pages

Given('I visit the form responses page for a specific form') do
  @form ||= FactoryBot.create(:form)
  visit form_form_responses_path(@form.id)
end

Given('I visit the form responses page for a specific student') do
  @student ||= FactoryBot.create(:student)
  visit student_form_responses_path(@student.id)
end

# Expectations for form responses

Then('I should see a list of responses for that form') do
  # Ensuring @form_responses are fetched correctly
  @form_responses ||= @form.form_responses
  @form_responses.each do |response|
    expect(page).to have_content(response.id)
  end
end

Then('I should not see responses from other forms') do
  other_form_responses = FormResponse.where.not(form: @form)
  other_form_responses.each do |response|
    expect(page).not_to have_content(response.id)
  end
end

# Expectations for student responses

Then('I should see a list of responses for that student') do
  # Ensuring @student_responses are fetched correctly
  @student_responses ||= @student.form_responses
  @student_responses.each do |response|
    expect(page).to have_content(response.id)
  end
end

Then('I should not see responses from other students') do
  other_student_responses = FormResponse.where.not(student: @student)
  other_student_responses.each do |response|
    expect(page).not_to have_content(response.id)
  end
end
# Step to visit the page showing all form responses
Given('I visit the form responses page for all forms') do
  visit form_responses_path # Adjust if this route is different in your application
end

# Step to verify that all form responses are displayed
Then('I should see a list of all form responses') do
  @all_form_responses = FormResponse.all
  @all_form_responses.each do |response|
    expect(page).to have_content(response.id) # Adjust to match actual displayed content, like response title or date
  end
end
