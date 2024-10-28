# features/step_definitions/students_steps.rb

Given('there is a student with ID {int}') do |id|
    @student = FactoryBot.create(:student, id: id) # Create a student with a specific ID
  end
  
  When('I visit the student details page') do
    visit student_path(@student) # Adjust based on how your student path is defined
  end
  
  Then("I should see the student's information") do
    expect(page).to have_content(@student.name) # Replace with actual attribute names
    expect(page).to have_content(@student.email) # Adjust based on your student attributes
    # Add more expectations based on the attributes you want to display
  end
  