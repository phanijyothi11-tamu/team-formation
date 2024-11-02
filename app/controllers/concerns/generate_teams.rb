module GenerateTeams
  extend ActiveSupport::Concern

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
    team_distribution = populate_teams_based_on_gender(team_distribution)
    team_distribution = optimize_teams_based_on_ethnicity(team_distribution)
    team_distribution = distribute_remaining_students(team_distribution)
    optimize_team_by_swaps(team_distribution)
  end

  def create_teams(final_team_distribution)
    final_team_distribution.each do |section, details|
      create_teams_for_section(section, details[:teams])
    end
  end

  def create_teams_for_section(section, teams)
    teams.each_with_index do |team_member_ids, index|
      formatted_members = format_team_members(team_member_ids)
      next if formatted_members.empty?

      @form.teams.create!(
        name: "Team #{index + 1}",
        section: section,
        members: formatted_members
      )
    end
  end

  def handle_error(error)
    Rails.logger.error("Team generation error: #{error.message}\n#{error.backtrace.join("\n")}")
    raise error
  end
end
