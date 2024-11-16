module TeamGenderBalance
  extend ActiveSupport::Concern
  include TeamDistributionHelpers

  # Input: team_distribution hash with structure:
  # {
  #   "A" => {
  #     students: Set[{student_id, gender, ethnicity, assigned, average, team_id, level}],
  #     by_gender: { "male" => Set[student_ids], "female" => Set[student_ids] },
  #     by_ethnicity: { ethnicity => Set[student_ids] },
  #     by_skill: { "low" => Set[ids], "medium" => Set[ids], "high" => Set[ids] },
  #     unassigned: Set[student_ids],
  #     teams: [{team_id, capacity, members[], composition{}, spots_left}]
  #   }
  # }
  #
  # Output: Modified team_distribution with balanced gender distribution
  def balance_by_gender(team_distribution)
    team_distribution.each do |section, section_data|
      # Step 1: Assign female students in pairs
      assign_female_students(section_data)

    # Check if there are multiple unassigned females left; if so, stop further assignments
    return team_distribution if multiple_unassigned_females?(section_data)


    # Step 2: Assign any single remaining female student
    assign_single_female_to_team(section_data)

    # Step 3: Assign 'other' gender students
    assign_others_to_teams(section_data)
    end
      team_distribution
  end

  private

  # Helper methods
  def assign_female_students(section_data)
    unassigned_females = filter_students(section_data, { gender: get_gender_option("female") })
    return if unassigned_females.size < 2

    assign_pairs_to_teams(section_data, unassigned_females)
  end

  # Refactored assign_pairs_to_teams method with reduced Cognitive Complexity
  def assign_pairs_to_teams(section_data, unassigned_females)
    section_data[:teams].each do |team|
      break if unassigned_females.size < 2 || (assign_pair_to_team(section_data, unassigned_females, team) && unassigned_females.size == 1)
    end
  end

  # Checks if there are multiple unassigned females left
  def multiple_unassigned_females?(section_data)
    unassigned_females = filter_students(section_data, { gender: get_gender_option("female") })
    unassigned_females.size > 1
  end

  # Attempts to find and assign a pair of female students to the team
  def assign_pair_to_team(section_data, unassigned_females, team)
    pair = find_student_pair(section_data, unassigned_females)
    return false unless pair

    assign_students_to_team(section_data, pair, team)
    unassigned_females.delete(pair.first)
    unassigned_females.delete(pair.last)
    true
  end

  # Finds a pair of female students based on matching criteria
  def find_student_pair(section_data, unassigned_females)
    unassigned_females_array = unassigned_females.to_a  # Convert Set to Array for sampling
    while unassigned_females_array.size >= 2
      student1_id = unassigned_females_array.sample
      match_id = select_match_id(section_data, student1_id, unassigned_females)
      return [ student1_id, match_id ] if match_id
    end
    nil
  end

  # Helper method to select a matching student ID for pairing
  def select_match_id(section_data, student1_id, unassigned_females)
    student1 = find_student(section_data, student1_id)
    potential_pairs = get_potential_pairs(unassigned_females, student1_id)
    match_id = find_matching_pair(section_data, student1, potential_pairs.to_a)

    if match_id.nil? && unassigned_females.size > 1
      # If no strict match is found, try without skill constraints
      match_id = potential_pairs.first
    end
    match_id
  end

  # Helper method to assign both students to the team
  def assign_students_to_team(section_data, pair, team)
    pair.each do |student_id|
      assign_student_to_team(section_data, student_id, team)
    end
  end

  # Helper method to find a student by ID
  def find_student(section_data, student_id)
    section_data[:students].find { |s| s[:student_id] == student_id }
  end

  # Helper method to get potential pairs excluding the current student
  def get_potential_pairs(unassigned_females, current_id)
    unassigned_females - [ current_id ]
  end


  def assign_single_female_to_team(section_data)
    unassigned_females = filter_students(section_data, { gender: get_gender_option("female") })
    return unless unassigned_females.size == 1

    student_id = unassigned_females.first
    # Find a team with exactly 2 females and an available spot (no need to ensure uniqueness for single female assignment)
    team = section_data[:teams].find do |t|
      t[:composition][:gender]["female"] == 2 && t[:spots_left] > 0
    end

    return unless team
    assign_student_to_team(section_data, student_id, team)
  end

  def assign_others_to_teams(section_data)
    unassigned_others = filter_students(section_data, { gender: get_gender_option("other") })
    return if unassigned_others.empty?

    # Keep track of teams that have already received an 'other' student
    teams_with_others = Set.new

    unassigned_others.each do |student_id|
      team = select_team_for_other(section_data, student_id, teams_with_others)
      next unless team  # Skip if no suitable team is found

      assign_student_to_team(section_data, student_id, team)
      teams_with_others.add(team[:team_id])  # Mark this team as having an 'other' student
    end
  end

  # Selects the appropriate team for an 'other' gender student
  def select_team_for_other(section_data, student_id, teams_with_others)
    other_student = find_student(section_data, student_id)
    needed_skill_level = determine_needed_skill_level(other_student[:average])

    # Find eligible teams matching the needed skill level, prioritizing capacity 4 over 3
    eligible_teams = find_eligible_teams_for_other(section_data, teams_with_others, needed_skill_level)

    if eligible_teams.any?
      # Assign to a randomly selected eligible team
      team = eligible_teams.sample
      team
    else
      # Assign to any team with exactly 2 females and available spots, prioritizing capacity 4 over 3
      fallback_team = find_fallback_team(section_data, teams_with_others)
      fallback_team
    end
  end

  # Finds eligible teams for assigning an 'other' student based on skill level
  def find_eligible_teams_for_other(section_data, teams_with_others, needed_skill_level)
    section_data[:teams].select do |team|
      team[:composition][:gender]["female"] == 2 &&
      team[:spots_left] > 0 &&
      !teams_with_others.include?(team[:team_id]) &&
      determine_needed_skill_level(calculate_team_average(section_data, team)) == needed_skill_level
    end.sort_by { |team| -team[:capacity] }  # Sort teams by descending capacity
  end

  # Finds a fallback team if no eligible teams match the needed skill level
  def find_fallback_team(section_data, teams_with_others)
    section_data[:teams].select do |team|
      team[:composition][:gender]["female"] == 2 &&
      team[:spots_left] > 0 &&
      !teams_with_others.include?(team[:team_id])
    end.sort_by { |team| -team[:capacity] }  # Sort teams by descending capacity
      .first
  end

  def get_gender_option(option_name)
    # Find the gender attribute
    gender_attr = get_gender_attribute

    # Convert options string to an array by splitting on commas and stripping whitespace
    options = gender_attr.options.split(",").map(&:strip)

    # Find the option matching the given name (case-insensitive)
    selected_option = options.find { |option| option.downcase == option_name.downcase }

    if selected_option.nil?
      raise "The 'gender' attribute does not have an option matching '#{option_name}'. Please add '#{option_name}' as an option."
    end

    selected_option
  end
end
