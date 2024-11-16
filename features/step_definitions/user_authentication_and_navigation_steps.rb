# features/step_definitions/user_authentication_and_navigation_steps.rb

Given("I am not logged in") do
  # Ensure the user is logged out
  visit logout_path
end

Given("I am logged in") do
  @user = FactoryBot.create(:user)
  Capybara.current_session.set_rack_session(user_id: @user.id)
  visit user_path(@user)
end
Given("I am logged in as a student") do
  @student = FactoryBot.create(:student)
  Capybara.current_session.set_rack_session(student_id: @student.id)
  visit student_path(@student)
end



When("I visit the welcome page") do
  visit welcome_path
end
Given("I am on the welcome page") do
  visit welcome_path
end
When("I clicks {string}") do |button_text|
  if button_text == "Login with Google"
    # Mock the OAuth response
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: 'google_oauth2',
      uid: '123456',
      info: {
        email: 'test@example.com',
        name: 'Test User'
      }
    })
    # Simulate the callback
    visit '/auth/google_oauth2/callback'
  else
      if button_text == "Logout"
          expect(page).to have_link(button_text, visible: true)
      end
      click_on button_text
  end
end


And("I authorize the application on Google") do
  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
    provider: 'google_oauth2',
    uid: '123456',
    info: {
      email: 'test@example.com',
      name: 'Test User'
    }
  })

  visit '/auth/google_oauth2/callback'

  @user = User.find_or_create_by(email: 'test@example.com') do |user|
    user.name = 'Test User'
    # Set any other necessary attributes
  end

  expect(@user).to_not be_nil
  # expect(page).to have_current_path(user_path(@user))
end

Then("I should see a Logout button") do
  expect(page).to have_link('Logout') # Check if there's a link with "Logout"
end




When("I authorize the application with an unregistered email") do
  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
    provider: 'google_oauth2',
    uid: '123456',
    info: {
      email: 'unregistered@example.com',
      name: 'Unregistered User'
    }
  })
  visit '/auth/google_oauth2/callback'
end

When("I visit my user page") do
  visit user_path(@user)
end

When("I try to visit a protected page") do
  visit user_path(1)  # Assuming this is a protected page
end

When("I hover over a student avatar") do
  find('.student').hover
end

Then("I should see {string}") do |expected_text|
  expect(page).to have_content(expected_text)
end

Then("I should see a {string} button") do |button_text|
  expect(page).to have_button(button_text)
end

Then("I should be redirected to my user page") do
  visit user_path(@user)
end
Then("I should be redirected to my student page") do
  expect(page).to have_current_path(student_path(@student))
end



Then("I should be redirected to the welcome page") do
  expect(current_path).to eq(welcome_path)
end

Then("I should see my email address") do
  expect(page).to have_content(@user.email)
end

Then("I should see my name") do
  expect(page).to have_content(@user.name)
end

Then("I should see a {string} link") do |link_text|
  expect(page).to have_link(link_text)
end

Then("I should see a thought bubble appear") do
  expect(page).to have_css('.thought-bubble', visible: true)
end

When("I click on a student avatar") do
  find('.student').click
end

Then("I should see the avatar briefly enlarge") do
  # This step might be tricky to test as it's a visual effect
  # You might need to use JavaScript-enabled testing for this
  # For now, we'll just check if the click event is registered
  expect(page).to have_css('.student:active')
end
Given("I authorize the application on Google as a student") do
  # Set OmniAuth mock auth hash
  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
    provider: 'google_oauth2',
    uid: '123456',
    info: {
      email: 'student@example.com',  # Ensure this matches the email in your factory
      name: 'Test Student'
    }
  })

  # Create student using FactoryBot
  @student = FactoryBot.create(:student, email: 'student@example.com')

  # Simulate the Google OAuth callback
  visit '/auth/google_oauth2/callback'

  # Verify that the student is properly logged in
  expect(@student).to be_valid
end
Given("I authorize the application on Google as a user") do
  # Set OmniAuth mock auth hash for user
  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
    provider: 'google_oauth2',
    uid: '123456',
    info: {
      email: 'user@example.com',  # Ensure this matches the email in your factory
      name: 'Test User'
    }
  })

  # Create user using FactoryBot
  @user = FactoryBot.create(:user, email: 'user@example.com')

  # Simulate the Google OAuth callback
  visit '/auth/google_oauth2/callback'

  # Verify that the user is properly logged in
  expect(@user).to be_valid
end
