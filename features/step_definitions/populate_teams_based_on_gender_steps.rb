Given("a form with a gender attribute exists") do
    @form = FactoryBot.create(:form, name: "Team Formation Form", description: "Gender-based team formation")
    @gender_attr = @form.form_attributes.create!(name: "Gender", field_type: "mcq", options: "male,female,other,prefer not to say")
  end
  
  Given(/(\d+) female students, (\d+) male students, (\d+) other students, and (\d+) prefer-not-to-say students have submitted responses/) do |females, males, others, prefer_not|
    # Create students and responses based on the given counts
    students = []
    
    # Create female students
    females.to_i.times do |i|
      student = FactoryBot.create(:student, name: "FemaleStudent#{i + 1}")
      FactoryBot.create(:form_response, form: @form, student: student, responses: { @gender_attr.id => "female" })
      students << student
    end
  
    # Create male students
    males.to_i.times do |i|
      student = FactoryBot.create(:student, name: "MaleStudent#{i + 1}")
      FactoryBot.create(:form_response, form: @form, student: student, responses: { @gender_attr.id => "male" })
      students << student
    end
  
    # Create "other" students
    others.to_i.times do |i|
      student = FactoryBot.create(:student, name: "OtherStudent#{i + 1}")
      FactoryBot.create(:form_response, form: @form, student: student, responses: { @gender_attr.id => "other" })
      students << student
    end
  
    # Create "prefer not to say" students
    prefer_not.to_i.times do |i|
      student = FactoryBot.create(:student, name: "PreferNotToSayStudent#{i + 1}")
      FactoryBot.create(:form_response, form: @form, student: student, responses: { @gender_attr.id => "prefer not to say" })
      students << student
    end
  
    @team_distribution = { section: { total_teams: 4, form_responses: students.map(&:form_responses).flatten } }
  end
  
  When("teams are populated based on gender") do
    @result = populate_teams_based_on_gender(@team_distribution)
  end
  
  Then("each team should have {int} female students if possible") do |count|
    @result[:section][:teams].each do |team|
      female_count = team.count { |student| student.form_responses.first.responses[@gender_attr.value] == "female" }
      expect(female_count).to be <= count
    end
  end
  
  Then("one team should have {int} female students") do |count|
    female_teams = @result[:section][:teams].select do |team|
      team.count { |student| student.form_responses.first.responses[@gender_attr.id] == "female" } == count
    end
    expect(female_teams.size).to eq(1)
  end
  
  Then("each team with {int} or {int} female students should have one \"other\" student if available") do |min_females, max_females|
    @result[:section][:teams].each do |team|
      female_count = team.count { |student| student.form_responses.first.responses[@gender_attr.id] == "female" }
      other_count = team.count { |student| student.form_responses.first.responses[@gender_attr.id] == "other" }
      if female_count.between?(min_females, max_females)
        expect(other_count).to eq(1).or be > 0
      end
    end
  end
  