# This controller handles CRUD operations for forms
# It also includes functionality for uploading and validating user data

class FormsController < ApplicationController
  include FormsHelper
  include FormPublishing
  include FormDeadlineManagement
  include FormUploading
  include PopulateTeamsBasedOnGender
  include GenerateTeams
  include ExportTeams
  require "roo"

  # Set @form instance variable for show, edit, update, and destroy actions
  before_action :set_form, only: %i[ show edit update destroy update_deadline publish close generate_teams view_teams]
  before_action :set_form, only: %i[ show edit update destroy update_deadline publish close generate_teams view_teams]

  # GET /forms
  def index
    # TODO: Implement form listing logic
    @forms = Form.all  # Currently fetches all forms, might need pagination or scoping
  end

  # GET /forms/1
  # Displays a specific form
  def show
    # @form is already set by before_action
  end

  # GET /forms/new
  # Displays the form for creating a new form
  def new
    # Initialize a new Form object for the form builder
    @form = Form.new
  end

  # GET /forms/1/edit
  # Displays the form for editing an existing form
  def edit
    # Build a new attribute for the form
    # This allows adding new attributes in the edit view
    @attribute = @form.form_attributes.build
  end

  # POST /forms
  # Creates a new form
  def create
    # Build a new form associated with the current user
    @form = current_user.forms.build(form_params)

    if @form.save
      # Redirect to edit page to add attributes after successful creation
      redirect_to edit_form_path(@form), notice: "Form was successfully created. You can now add attributes."
    else
      # If save fails, set error message and re-render the new form
      flash.now[:alert] = @form.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /forms/1
  # Updates an existing form
  def update
    # Allow params with or without 'form' key
    update_params = params[:form] || params

    if @form.update(update_params.permit(:name, :description, :deadline))
      # If update succeeds, set success message and redirect to the form
      flash[:notice] = "Form was successfully updated."
      redirect_to @form
    else
      # If update fails, rebuild the attribute and re-render the edit form
      @attribute = @form.form_attributes.build
      render :edit, status: :unprocessable_entity
    end
  end

  # GET /forms/#id/preview
  def preview
    @form = Form.find(params[:id])
    render partial: "preview"
  end

  # GET /forms/#id/duplicate
  # opens new /forms/#new_id/edit
  def duplicate
    original_form = Form.find(params[:id])
    result = Forms::DuplicationService.call(original_form)

    if result.success?
      redirect_to edit_form_path(result.form), notice: "Form was successfully duplicated."
    else
      redirect_to edit_form_path(original_form),
                  alert: "Failed to duplicate the form. #{result.errors&.join(', ')}"
    end
  end

  # DELETE /forms/1
  # Deletes a specific form
  def destroy
    @form.destroy!

    respond_to do |format|
      # Redirect to user's show page after successful deletion
      format.html { redirect_to user_path(current_user), status: :see_other, notice: "Form was successfully destroyed." }
      format.json { head :no_content }
    end
  end
  # GET /forms/1/view_teams
  def view_teams
    @teams = @form.teams
  end
  private
    # Sets @form instance variable based on the id parameter
    # Only finds forms belonging to the current user for security
    def set_form
      @form = current_user.forms.find(params[:id])
    end

    # Define allowed parameters for form creation and update
    # This is a security measure to prevent mass assignment vulnerabilities
    def form_params
      params.require(:form).permit(:name, :description, :deadline)
    rescue ActionController::ParameterMissing
      # If :form key is missing, permit name and description directly from params
      # This allows for more flexible parameter handling
      params.permit(:name, :description, :deadline)
    end

    def calculate_teams
      # Fetch all form responses for this form and group them by the student's section
      # The 'includes(:student)' eager loads the associated student data to avoid N+1 queries
      # The result is a hash where keys are section names and values are arrays of form responses
      sections = @form.form_responses.includes(:student).group_by { |response| response.student.section }

      # Initialize an empty hash to store the team distribution for each section
      team_distribution = {}

      # Iterate over each section and its responses
      sections.each do |section, responses|
        # Count the total number of students (responses) in this section
        total_students = responses.count

        # Calculate the base number of teams of 4 we can form
        base_teams = total_students / 4

        # Calculate how many students are left over after forming teams of 4
        remainder = total_students % 4

        # Determine the final number of teams of 4 based on the remainder
        # We adjust this to allow for teams of 3 when necessary
        teams_of_4 = case remainder
        when 0 then base_teams     # If no remainder, all teams are of size 4
        when 1 then base_teams - 2 # If remainder 1, we need 3 teams of 3
        when 2 then base_teams - 1 # If remainder 2, we need 2 teams of 3
        when 3 then base_teams     # If remainder 3, we need 1 team of 3
        end

        teams_of_3 = remainder.zero? ? 0 : 4 - remainder

        # Store the calculated distribution for this section
        team_distribution[section] = {
          total_students: total_students,  # Total number of students in this section
          teams_of_4: teams_of_4,          # Number of teams with 4 members
          teams_of_3: teams_of_3,          # Number of teams with 3 members
          total_teams: teams_of_4 + teams_of_3,  # Total number of teams in this section
          form_responses: responses        # Array of form response objects for this section
        }
      end

      # Return the complete team distribution hash
      # This hash contains the team distribution data for all sections
      team_distribution
    end
    # def populate_teams_based_on_gender(team_distribution)
    #   # Dummy function: Just return the input for now
    #   team_distribution.each do |section, details|
    #     details[:teams] = Array.new(details[:total_teams]) { [] }
    #     details[:remaining_students] = details[:form_responses].map(&:student)
    #   end
    #   team_distribution
    # end

    def optimize_teams_based_on_ethnicity(team_distribution)
      # Dummy function: Just return the input for now
      team_distribution
    end

    def distribute_remaining_students(team_distribution)
      # Dummy function: Distribute remaining students randomly
      team_distribution
    end

    def optimize_team_by_swaps(team_distribution)
      # Dummy function: Just return the input for now
      team_distribution
    end
    def format_team_members(team_members_ids)
      return [] if team_members_ids.blank?

      students = Student.where(id: team_members_ids)
      formatted_members = students.map do |student|
        {
          id: student.id,
          name: student.name,
          uin: student.uin,
          email: student.email
        }
      end

      formatted_members.presence || []
    end

    # Helper method to calculate the weighted average score for a student
    def calculate_weighted_average(response)
      excluded_attrs = [ "gender", "ethnicity" ]
      attributes = response.form.form_attributes.reject { |attr| excluded_attrs.include?(attr.name.downcase) }

      total_score = 0.0
      total_weight = 0.0

      attributes.each do |attribute|
        weightage = attribute.weightage
        student_response = response.responses[attribute.id.to_s]  # Convert id to string

        if student_response.present?
          score = student_response.to_f
          total_score += score * weightage
          total_weight += weightage
        end
      end
      # Return the weighted average score
      total_weight > 0 ? (total_score / total_weight) : 0
    end
end
