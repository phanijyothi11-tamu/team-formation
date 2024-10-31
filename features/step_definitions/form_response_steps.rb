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
