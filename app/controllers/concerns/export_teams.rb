module ExportTeams
  extend ActiveSupport::Concern
  def export_teams
    @form = Form.find(params[:id])
    @teams = @form.teams

    if @teams.empty?
      flash[:alert] = "No teams available for export."
      redirect_to view_teams_form_path(@form)
      return
    end

    respond_to do |format|
      format.xlsx {
        response.headers["Content-Disposition"] = 'attachment; filename="teams.xlsx"'
        render xlsx: "export_teams", filename: "teams.xlsx"
      }
      format.csv {
        send_data generate_csv(@teams), filename: "teams-#{Date.today}.csv"
      }
      format.pdf {
        render pdf: "teams-#{Date.today}", template: "forms/export_teams", layout: "pdf", disposition: "attachment"
      }
    end
  end
  private
  def generate_csv(teams)
    CSV.generate(headers: true, encoding: Encoding::UTF_8) do |csv|
      csv << [ "Section", "Team Name", "Student Name", "UIN", "Email" ]

      teams.each do |team|
        team.members.each do |member|
          csv << [ team.section, team.name, member["name"], member["uin"], member["email"] ]
        end
      end
    end
  end
end
