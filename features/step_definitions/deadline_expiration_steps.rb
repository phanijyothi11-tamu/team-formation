# Existing steps
When("I publish the form") do
  visit form_path(@form)
  click_button "Publish Form"
end

Then("the form should be automatically closed") do
  @form.reload
  expect(@form.published).to be false
end

# New steps needed
When("I wait for {int} seconds") do |seconds|
  # Using Capybara's timer instead of sleep for better test stability
  Capybara.using_wait_time(seconds + 1) do
    expect(page).to have_content(@form.name)
  end
end

Then('I should see {string} status for that form') do |status|
  within('tr', text: @form.name) do
    expect(page).to have_css('.badge', text: status)
  end
end
