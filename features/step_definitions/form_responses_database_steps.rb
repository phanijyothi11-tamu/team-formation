  # features/step_definitions/form_responses_database_steps.rb

  Given("I have added the following attributes to the form:") do |table|
    table.hashes.each do |attribute|
      @form.form_attributes.create!(
        name: attribute["Name"],
        field_type: attribute["Field Type"],
        options: attribute["Options"],
        min_value: attribute["Min Value"].presence&.to_i,
        max_value: attribute["Max Value"].presence&.to_i
      )
    end
  end

  When("a student submits their UIN and responses") do |table|
    # Extract UIN and responses from the table
    @student_uin = "987654321" # Example UIN; you can randomize or specify as needed

    responses = {}
    table.hashes.each do |row|
      attribute = @form.form_attributes.find_by(name: row["Attribute Name"])
      raise "Attribute '#{row['Attribute Name']}' not found in the form." unless attribute

      responses[attribute.id.to_s] = row["Response"]
    end

    # Submit the form response
    visit new_form_form_response_path(@form)

    fill_in "UIN", with: @student_uin

    @form.form_attributes.each do |attribute|
      case attribute.field_type
      when 'text_input'
        fill_in "form_response_responses_#{attribute.id}", with: responses[attribute.id.to_s]
      when 'mcq'
        select responses[attribute.id.to_s], from: "form_response_responses_#{attribute.id}"
      when 'scale'
        fill_in "form_response_responses_#{attribute.id}", with: responses[attribute.id.to_s]
      else
        fill_in "form_response_responses_#{attribute.id}", with: responses[attribute.id.to_s]
      end
    end

    click_button "Submit Response"
  end

  Then("the response should be stored in the form_responses table") do
    saved_response = FormResponse.find_by(uin: @student_uin, form_id: @form.id)
    expect(saved_response).not_to be_nil, "Expected FormResponse with UIN #{@student_uin} to be present, but it was not found."

    @form.form_attributes.each do |attribute|
      expected_value = saved_response.responses[attribute.id.to_s]
      actual_value = case attribute.field_type
      when 'scale'
                       saved_response.responses[attribute.id.to_s].to_i
      else
                       saved_response.responses[attribute.id.to_s]
      end
      expect(expected_value).to eq(expected_value), "Expected response for '#{attribute.name}' to be '#{expected_value}', but got '#{actual_value}'."
    end
  end

  Then("I should see a confirmation message {string}") do |message|
    expect(page).to have_content(message)
  end

  Given("I login as a professor") do
    @user= User.create!(name: "Professor3", email: "professor3@example.com", uin: "121456789")
    page.set_rack_session(user_id: @user.id)
  end

  Given('I have published a form {string}') do |string|
    @form1 = Form.create!(name: "Access Form", description: "Testing form access", user_id: @user.id, published: true)
    @attribute = @form1.form_attributes.create!(
    name: "question1",
    field_type: 'text_input',
    weightage: 0.5
    )
  end

  Given('I have uploaded a list of students to a form') do
    student3 = Student.find_by(id: 3) || create(:student, id: 3, name: "Student Three", email: "student3@example.com", uin: "121111111")
    student4 = Student.find_by(id: 4) || create(:student, id: 4, name: "Student Four", email: "student4@example.com", uin: "212222222")

    create(:form_response, form: @form1, student: student3)
  end

  Given('the eligible list contains student_id {string} and not {string}') do |string, string2|
    expect(@form1.student_ids).to have_content(string)
    expect(@form1.student_ids).not_to have_content(string2)
  end
  
  When('{string} logs into the system') do |string|
    visit student_path(4)
  end

  Then('the student should not see {string}') do |string|
    expect(page).not_to have_content(@form1.name)
  end