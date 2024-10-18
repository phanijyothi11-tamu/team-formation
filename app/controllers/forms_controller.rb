# This controller handles CRUD operations for forms
# It also includes functionality for uploading and validating user data

class FormsController < ApplicationController
  include FormsHelper
  require "roo"

  # Set @form instance variable for show, edit, update, and destroy actions
  before_action :set_form, only: %i[ show edit update destroy update_deadline publish ]

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
    duplicated_form = original_form.dup

    # Suggest a new name for the duplicated form
    duplicated_form.name = "#{original_form.name} - Copy"

    # Duplicate associated attributes
    original_form.form_attributes.each do |attribute|
      duplicated_attribute = attribute.dup
      duplicated_attribute.assign_attributes(attribute.attributes.except("id", "created_at", "updated_at", "form_id"))
      duplicated_form.form_attributes << duplicated_attribute
    end

    if duplicated_form.save
      # Redirect to the edit page of the duplicated form in a new window
      redirect_to edit_form_path(duplicated_form), notice: "Form was successfully duplicated."
    else
      redirect_to edit_form_path(original_form), alert: "Failed to duplicate the form."
    end
  end


  def upload
  end

  def validate_upload
    if params[:file].present?
      file = params[:file].path

      begin
        spreadsheet = Roo::Spreadsheet.open(file)
        header_row = spreadsheet.row(1)

        if header_row.nil? || header_row.all?(&:blank?)
          flash[:alert] = "The first row is empty. Please provide column names."
          redirect_to user_path(current_user) and return
        end

        users_to_create = []
        (2..spreadsheet.last_row).each do |index|
          row = spreadsheet.row(index)

          user_data = validate_row(row, index, header_row)
          return redirect_to user_path(current_user) if user_data.nil?

          users_to_create << user_data
        end

        User.insert_all(users_to_create)
        flash[:notice] = "All validations passed."
      rescue StandardError => e
        flash[:alert] = "An error occurred: #{e.message}"
      end
    else
      flash[:alert] = "Please upload a file."
    end

    redirect_to user_path(current_user)
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

  # Add a new method for updating deadline from index page
  def update_deadline
    if @form.update(deadline_params)
      # Redirect to the index page with success notice
      redirect_to user_path(@form.user), notice: "Deadline was successfully updated."
    else
      redirect_to user_path(@form.user), alert: "Failed to update the deadline."
    end
  end

  # POST /forms/1/publish
  def publish
    if @form.can_publish?
      publish_form
    else
      handle_publish_error
    end
  end


  private
    def publish_form
      if @form.update(published: true)
        redirect_to @form, notice: "Form was successfully published."
      else
        redirect_to @form, alert: "Failed to publish the form."
      end
    end

    def handle_publish_error
      reasons = collect_error_reasons
      flash[:alert] = "Form cannot be published. Reasons: #{reasons.join(', ')}."
      redirect_to @form
    end

    def collect_error_reasons
      reasons = []
      reasons << "no attributes" unless @form.has_attributes?
      reasons << "no associated students" unless @form.has_associated_students?
      reasons
    end

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

    def deadline_params
      params.require(:form).permit(:deadline)
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
end


    def populate_teams_based_on_gender(team_distribution)
      # Iterate over each section in the team distribution hash
      team_distribution.each do |section, details|
        # Get the number of teams of 4 and teams of 3 for the section
        teams_of_4 = details[:teams_of_4]
        teams_of_3 = details[:teams_of_3]
        total_teams = details[:total_teams]

        # Create empty teams based on the number of teams of 4 and 3 #change 1
        teams = Array.new(teams_of_4) { [] } + Array.new(teams_of_3) { [] }

        # Get form responses and initialize lists for all gender categories
        responses = details[:form_responses]
        female_students = []
        other_students = []
        male_students = []
        prefer_not_to_say_students = []

        # Identify the gender attribute (dynamic, based on professor input)
        gender_attribute = find_gender_attribute(details[:form])

        # Categorize students by their gender and calculate their weighted average score
        responses.each do |response|
          student = response.student
          gender_value = response.responses[gender_attribute.id]
          weighted_average = calculate_weighted_average(response)

          case gender_value.downcase
          when "female"
            female_students << { student: student, score: weighted_average }
          when "other"
            other_students << { student: student, score: weighted_average }
          when "male"
            male_students << { student: student, score: weighted_average }
          when "prefer not to say"
            prefer_not_to_say_students << { student: student, score: weighted_average }
          end
        end

        # Sort the female and other students by their weighted average scores (descending)
        female_students.sort_by! { |s| -s[:score] }
        other_students.sort_by! { |s| -s[:score] }

        # Initialize pointers and team index
        i = 0
        j = female_students.size - 1
        team_index = 0

        # Assign females to teams based on the specified conditions
        while i <= j && team_index < teams.size
          remaining_females = j - i + 1

          if remaining_females == 3
            # Assign the last 3 females to one team
            teams[team_index] << female_students[i][:student]
            i += 1
            teams[team_index] << female_students[i][:student]
            i += 1
            teams[team_index] << female_students[i][:student]
            i += 1
            team_index += 1
            break
          elsif remaining_females >= 2
            # Assign 2 females to the team
            teams[team_index] << female_students[i][:student]  # High scorer
            i += 1
            teams[team_index] << female_students[j][:student]  # Low scorer
            j -= 1
            team_index += 1
          end
        end

        # Assign one "other" student to each team with 2 or 3 females
        teams.each do |team|
          break if other_students.empty? # Stop if no "other" students left
          if team.size >= 2 && team.size<4 # Ensure teams with 2 or 3 females get an "other" student
            team << other_students.shift[:student]
          end
        end

        # Store the final teams and the remaining students for this section
        details[:teams] = teams
        details[:form_responses] = form_responses

        # Update the section in the team_distribution
        team_distribution[section] = details
        end

        # Return the updated team distribution hash
        team_distribution
    end


    # Helper method to identify the gender attribute from the form's attributes
    def find_gender_attribute(form)
      form.form_attributes.find { |attr| attr.name.downcase == "gender" }
    end


    # Helper method to calculate the weighted average score for a student
    def calculate_weighted_average(response)
      attributes = response.form.form_attributes.reject { |attr| attr.name.downcase.in?([ "gender", "ethnicity" ]) }
      total_score = 0.0
      total_weight = 0.0

      attributes.each do |attribute|
        weightage = attribute.weightage || 1.0 # Default weightage to 1 if not set
        student_response = response.responses[attribute.id]
        score = student_response.to_f

        total_score += score * weightage
        total_weight += weightage
      end

      # Return the weighted average score
      total_weight
    end
