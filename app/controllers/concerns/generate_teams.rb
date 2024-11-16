module GenerateTeams
  extend ActiveSupport::Concern
  include TeamCalculation
  include TeamGenderBalance
  include TeamEthnicityBalance
  include TeamSkillBalance

  def generate_teams
    ActiveRecord::Base.transaction do
      begin
        @form.teams.destroy_all
        final_team_distribution = apply_team_formation_pipeline
        create_teams(final_team_distribution)
        redirect_to view_teams_form_path(@form), notice: "Teams have been successfully generated!"
      rescue StandardError => e
        handle_error(e)
      end
    end
  end

  def apply_team_formation_pipeline
    team_distribution = calculate_teams
    team_distribution = balance_by_gender(team_distribution)
    team_distribution = balance_by_ethnicity(team_distribution)
    balance_by_skills(team_distribution)
  end

  def create_teams(final_team_distribution)
    final_team_distribution.each do |section, section_data|
      create_teams_for_section(section, section_data[:teams])
    end
  end

  def create_teams_for_section(section, teams)
    teams.each do |team|
      formatted_members = format_team_members(team[:members])
      next if formatted_members.empty?

      @form.teams.create!(
        name: "Team #{team[:team_id]}",
        section: section,
        members: formatted_members
      )
    end
  end

  def format_team_members(member_ids)
    member_ids.reject(&:zero?).map do |student_id|
      student = Student.find(student_id)
      { id: student.id, name: student.name }
    end
  end

  def handle_error(error)
    Rails.logger.error("Team generation error: #{error.message}\n#{error.backtrace.join("\n")}")
    raise error
  end
end
