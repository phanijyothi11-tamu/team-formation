# This controller handles CRUD operations for forms
# It also includes functionality for uploading and validating user data

class FormsController < ApplicationController
  include FormsHelper
  require "roo"

  # Set @form instance variable for show, edit, update, and destroy actions
  before_action :set_form, only: %i[ show edit update destroy update_deadline publish close ]

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
      log_modification("Create", "Form #{@form.name} was created.")
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
      log_modification("Update", "Form #{@form.name} was updated.")
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
    @form = Form.find(params[:id])
  end

  def validate_upload
    if params[:file].present?
      file = params[:file].path

      begin
        spreadsheet = Roo::Spreadsheet.open(file)
        header_row = spreadsheet.row(1)

        if header_row.nil? || header_row.all?(&:blank?)
          flash[:alert] = "The first row is empty. Please provide column names."
          redirect_to edit_form_path(params[:id]) and return
        end

        users_to_create = []
        (2..spreadsheet.last_row).each do |index|
          row = spreadsheet.row(index)

          user_data = validate_row(row, index, header_row)
          return redirect_to edit_form_path(params[:id]) if user_data.nil?

          users_to_create << user_data
        end

        Student.upsert_all(users_to_create, unique_by: :uin)
        student_ids = users_to_create.map { |student| Student.find_by(uin: student[:uin])&.id }.compact
        existing_student_ids = FormResponse.where(form_id: params[:id]).pluck(:student_id)
        form_responses_to_create = student_ids.reject { |id| existing_student_ids.include?(id) }.map do |student_id|
          {
            student_id: student_id,
            form_id: params[:id],
            responses: {}.to_json
          }
        end
        FormResponse.insert_all(form_responses_to_create) if form_responses_to_create.any?
        flash[:notice] = "All validations passed."
      rescue StandardError => e
        flash[:alert] = "An error occurred: #{e.message}"
      end
    else
      flash[:alert] = "Please upload a file."
    end

    redirect_to edit_form_path(params[:id])
  end








  # DELETE /forms/1
  # Deletes a specific form
  def destroy
    @form.destroy!

    log_modification("Destroy", "Form #{@form.id} was destroyed.")
    respond_to do |format|
      # Redirect to user's show page after successful deletion
      format.html { redirect_to user_path(current_user), status: :see_other, notice: "Form was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def show_modifications
    @form = Form.find(params[:id])
    @modifications = @form.modifications || {}
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

  # POST /forms/1/close
  def close
    if @form.update(published: false)
      redirect_to @form, notice: "Form was successfully closed."
    else
      redirect_to @form, alert: "Failed to close the form."
    end
  end

  private

    def log_modification(modification_type, details)
      # Initialize modifications if not already set
      @form.modifications ||= {}
      @form.modifications[Time.current] = { type: modification_type, details: details }

      # Save the modifications back to the form
      @form.save
    end

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
