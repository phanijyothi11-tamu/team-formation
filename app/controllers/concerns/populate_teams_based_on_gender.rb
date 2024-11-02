module PopulateTeamsBasedOnGender
    extend ActiveSupport::Concern
    def populate_teams_based_on_gender(team_distribution)
      team_distribution.each do |section, details|
        teams = initialize_teams(details)
        response_assignment_tracker = initialize_tracker(details[:form_responses])
        gender_attribute = fetch_gender_attribute(details[:form_responses].first)

        categorized_students = categorize_students(details[:form_responses], gender_attribute)
        assign_students_to_teams(teams, categorized_students, response_assignment_tracker)

        details[:teams] = teams
        details[:response_assignment_tracker] = response_assignment_tracker
      end
      team_distribution
    end

    def initialize_teams(details)
      teams = []
      details[:teams_of_4].times { teams << Array.new(4, 0) }
      details[:teams_of_3].times { teams << Array.new(3, 0) }
      teams
    end

    def initialize_tracker(responses)
      responses.each_with_object({}) do |response, tracker|
        tracker[response.id] = { assigned: false, response: response }
      end
    end

    def fetch_gender_attribute(response)
      form = Form.find(response.form_id)
      form.form_attributes.find { |attr| attr.name.downcase == "gender" }
    end

    def categorize_students(responses, gender_attribute)
      students_by_gender = initialize_gender_groups

      responses.each do |response|
        next unless valid_gender_response?(response, gender_attribute)
        assign_student_to_category(students_by_gender, response, gender_attribute)
      end

      sort_gender_groups(students_by_gender)
      students_by_gender
    end

    # Helper Methods

    def initialize_gender_groups
      { female: [], other: [], male: [], prefer_not_to_say: [] }
    end

    def assign_student_to_category(students_by_gender, response, gender_attribute)
      gender_category = determine_gender_category(response, gender_attribute)
      return if gender_category.nil?

      student_data = build_student_data(response, gender_attribute)
      students_by_gender[gender_category] << student_data
    end

    def determine_gender_category(response, gender_attribute)
      case response.responses[gender_attribute.id.to_s]&.downcase
      when "female" then :female
      when "other" then :other
      when "male" then :male
      when "prefer not to say" then :prefer_not_to_say
      end
    end

    def sort_gender_groups(students_by_gender)
      students_by_gender[:female].sort_by! { |s| -s[:score] }
      students_by_gender[:other].sort_by! { |s| -s[:score] }
    end

    def valid_gender_response?(response, gender_attribute)
      gender_value = response.responses[gender_attribute.id.to_s]
      !gender_value.nil? && !gender_value.strip.empty?
    end

    def build_student_data(response, gender_attribute)
      student = response.student
      { student: student, response: response, score: calculate_weighted_average(response) }
    end

    def assign_students_to_teams(teams, categorized_students, tracker)
      female_students = categorized_students[:female]
      other_students = categorized_students[:other]

      assign_female_students(teams, female_students, tracker)
      assign_other_students(teams, other_students, tracker)
    end

    def assign_female_students(teams, female_students, tracker)
      if female_students.size.even?
        assign_even_female_students(teams, female_students, tracker)
      else
        assign_odd_female_students(teams, female_students, tracker)
      end
    end

    def assign_even_female_students(teams, female_students, tracker)
      i, j, team_index = 0, female_students.size - 1, 0
      while i <= j && team_index < teams.size
        teams[team_index][teams[team_index].index(0)] = female_students[i][:student].id
        tracker[female_students[i][:response].id][:assigned] = true
        i += 1

        teams[team_index][teams[team_index].index(0)] = female_students[j][:student].id
        tracker[female_students[j][:response].id][:assigned] = true
        j -= 1
        team_index += 1
      end
    end

    def assign_odd_female_students(teams, female_students, tracker)
      i, j = 0, female_students.size - 1

      teams.each_with_index do |team, team_index|
        break if i > j # Stop if all females are assigned

        assign_students_to_team(team, female_students, (i..j), tracker)
        i, j = update_indices(i, j, female_students.size)
      end
    end

    def assign_students_to_team(team, female_students, range, tracker)
      remaining_females = range.end - range.begin + 1

      if remaining_females == 3
        assign_three_females(team, female_students[range], tracker)
      elsif remaining_females >= 2
        assign_two_females(team, female_students[range.begin], female_students[range.end], tracker)
      end
    end

    def assign_three_females(team, female_students, tracker)
      3.times do |n|
        assign_student_to_team(team, female_students[n], tracker)
      end
    end

    def assign_two_females(team, high_scorer, low_scorer, tracker)
      assign_student_to_team(team, high_scorer, tracker)
      assign_student_to_team(team, low_scorer, tracker)
    end

    def assign_student_to_team(team, student_data, tracker)
      team[team.index(0)] = student_data[:student].id
      tracker[student_data[:response].id][:assigned] = true
    end

    def update_indices(i, j, total_students)
      # Update indices based on how many students were assigned
      if j - i + 1 == 3
        return i + 3, j # Move both indices for 3 females
      elsif j - i + 1 >= 2
        return i + 1, j - 1 # Move for 2 females
      end
      return i, j # No change if fewer than 2
    end

    def assign_other_students(teams, other_students, tracker)
      teams.each do |team|
        break if other_students.empty?
        if valid_for_other_student_assignment?(team)
          assign_other_student_to_team(team, other_students, tracker)
        end
      end
    end

    def valid_for_other_student_assignment?(team)
      team.count { |member| member != 0 } >= 2 && team.include?(0)
    end

    def assign_other_student_to_team(team, other_students, tracker)
      student = other_students.shift
      team[team.index(0)] = student[:student].id
      tracker[student[:response].id][:assigned] = true
    end
end
