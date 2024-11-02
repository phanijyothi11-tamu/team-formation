Given("I log in as a professor") do
    @user= User.create!(name: "Professor2", email: "professor2@example.com", uin: "123456789")
    page.set_rack_session(user_id: @user.id)
  end

  Given("I have already published a form") do
    @form = Form.create!(name: "My Form", description: "This is my form", user_id: @user.id, published: true)
    @attribute = @form.form_attributes.create!(
    name: "question1",
    field_type: 'text_input',
    weightage: 0.5
    )
  end

  And("students have submitted their responses") do
    @student = FactoryBot.create(:student)
    @form_response = FactoryBot.create(:form_response, form: @form, student: @student, responses: { "1" => "Ans1" })
  end

  When("I click on {string} to view responses for a form") do |button_text|
    visit user_path(@user)
    click_link(button_text)
  end

  Then("I should see a list of student responses") do
    expect(page).to have_content("Responses")
    expect(page).to have_selector("table") # displaying responses in a table
  end

  And("I select a response and click on {string}") do |button_text|
    first('table tbody tr').click_link(button_text)
  end

  Then("I should see the detailed response") do
    expect(page).to have_content("Response by Student ID:")
    expect(page).to have_content(@student.id.to_s) # Ensure the student ID is displayed
    expect(page).to have_content("Ans1") # Check that the response is displayed
  end

  Given("I have created a form that is not published") do
    @form = FactoryBot.create(:form,
      user: @user,
      published: false,
      name: "Test Form #{Time.current.to_i}",
      description: "This is a test form"
    )
    @form.form_attributes.create!(
      name: "Question 1",
      field_type: 'text_input',
      weightage: 1
    )
    step "students with IDs 1 and 2 have access to the form"
    step "the deadline is set"
  end

  Given("I have created a form that is published") do
    @form = FactoryBot.create(:form,
      user: @user,
      published: true,
      name: "Test Form #{Time.current.to_i}",
      description: "This is a test form"
    )
    @form.form_attributes.create!(
      name: "Question 1",
      field_type: 'text_input',
      weightage: 1
    )
    step "students with IDs 1 and 2 have access to the form"
    step "the deadline is set"
  end

  When("I visit my user profile page") do
    visit user_path(@user)
  end

  Then("I should not see {string} for that form") do |button_text|
    within('tr', text: @form.name) do
      expect(page).not_to have_content(button_text)
    end
  end

  Then("I should see {string} and {string} buttons for that form") do |button1, button2|
    within('tr', text: @form.name) do
      expect(page).to have_content(button1)
      expect(page).to have_content(button2)
    end
  end

  Then("I should not see {string} or {string} buttons for that form") do |button1, button2|
    within('tr', text: @form.name) do
      expect(page).not_to have_content(button1)
      expect(page).not_to have_content(button2)
    end
  end

  Then("I should see {string} for that form") do |button_text|
    within('tr', text: @form.name) do
      expect(page).to have_content(button_text)
    end
  end
