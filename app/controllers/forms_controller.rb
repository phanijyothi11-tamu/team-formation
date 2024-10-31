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

    respond_to do |format|
      # Redirect to user's show page after successful deletion
      format.html { redirect_to user_path(current_user), status: :see_other, notice: "Form was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def calculate_teams_dummy
    team_distribution = self.dummy_calculate_teams  # Call the function
    team_distribution_with_genders = self.dummy_populate_teams_based_on_gender(team_distribution)

    @pretty_team_distribution = format_team_distribution(team_distribution_with_genders)
  end

  def format_team_distribution(distribution)
    return "null" if distribution.blank?

    output = ""
    distribution.each do |team_id, team_info|
      output << "Team ID: #{team_id}\n"
      output << "Total Students: #{team_info[:total_students]}\n"
      output << "Teams of 4: #{team_info[:teams_of_4]}\n"
      output << "Teams of 3: #{team_info[:teams_of_3]}\n"
      output << "Total Teams: #{team_info[:total_teams]}\n"
      output << "Students:\n"

      team_info[:teams].each_with_index do |team, index|
        output << "  Team #{index + 1}: "
        output << team.map { |student| "#{student.name} (UIN: #{student.uin})" }.join(", ")
        output << "\n"
      end

      output << "Remaining Students:\n"
      team_info[:remaining_students].each do |remaining_student|
        student = remaining_student[:student]
        output << "  #{student.name} (UIN: #{student.uin}), Score: #{remaining_student[:score]}\n"
      end

      output << "\n"
    end

    output
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

    def dummy_calculate_teams
      # Fetch all form responses for this form and group them by the student's section
      # The 'includes(:student)' eager loads the associated student data to avoid N+1 queries
      # The result is a hash where keys are section names and values are arrays of form responses
      sections = Form.find(1).form_responses.includes(:student).group_by { |response| response.student.section }

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

    def dummy_populate_teams_based_on_gender(team_distribution)
      team_distribution.each do |section, details|
        teams = initialize_teams(details[:total_teams])
        # create an empty var to store the based on ethnicities and genders
        @form = Form.find(details[:form_responses].first.form_id)
        # gender_attribute = get_gender_attribute(details[:form_responses])
        ethnicity_attribute = get_ethnicity_attribute(details[:form_responses])
        genders = Attribute.where(form_id: @form.id, field_type: "mcq").where("LOWER(name) = ?", "gender").limit(1).pluck(:options).first.to_s.split(",")
        ethnicities = Attribute.where(form_id: @form.id, field_type: "mcq").where("LOWER(name) = ?", "ethnicity").limit(1).pluck(:options).first.to_s.split(",")
        categorized_students = initialize_categorized_students(genders, ethnicities)

        # populate based on gender and ethnicity
        gender_ethnicity_populate(details[:form_responses], categorized_students)

        # calculate minorities
        segregation = calculate_minorities(details[:form_responses], ethnicities, ethnicity_attribute)
        minorities = segregation[0]
        majorities = segregation[1]

        # Categorize students by gender
        students_by_gender_ethnicity = populate_teams_by_gender_and_minority(teams, categorized_students, minorities, majorities, team_distribution)

        # Distribute female students into teams
        distribute_female_students(students_by_gender[:female], teams)

        # Assign one "other" student to teams with 2 or 3 females
        distribute_other_students(students_by_gender[:other], teams)

        # Store the final teams and remaining students
        details[:teams] = teams
        details[:remaining_students] = collect_remaining_students(students_by_gender)

        # Update the section in the team_distribution
        # team_distribution[section] = details
        team_distribution[section] = students_by_gender_ethnicity
      end
      team_distribution
    end

    def calculate_minorities(details, ethnicities, ethnicity_attribute)
      ethnicity_counts = Hash.new(0)
      total_population = responses.size
      responses.each do |response|
        ethnicity_value = response.responses[ethnicity_attribute.id.to_s]
        ethnicity_counts[ethnicity_value] += 1 if ethnicity_value.present?
      end
      threshold = total_population * 0.3
      minority_ethnicities = ethnicity_counts.select { |_, count| count < threshold }.keys
      remaining_ethnicities = ethnicity_counts.select { |_, count| count >= threshold }.keys
      [ minority_ethnicities, remaining_ethnicities ]
    end

    def gender_ethnicity_populate(responses, categorized_students)
      responses.each do |response|
        ethnicity_value = response.responses[ethnicity_attribute.id.to_s]
        gender_value = response.responses[gender_attribute.id.to_s]
        categorized_students[ethnicity_value][gender_value] << response.student_id unless categorized_students[ethnicity_value][gender_value].include?(response.student_id)
      end
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
    team_distribution.each do |section, details|
      teams = initialize_teams(details[:total_teams])
      gender_attribute = get_gender_attribute(details[:form_responses])

      # Categorize students by gender
      students_by_gender = categorize_students_by_gender(details[:form_responses], gender_attribute)

      # Distribute female students into teams
      distribute_female_students(students_by_gender[:female], teams)

      # Assign one "other" student to teams with 2 or 3 females
      distribute_other_students(students_by_gender[:other], teams)

      # Store the final teams and remaining students
      details[:teams] = teams
      details[:remaining_students] = collect_remaining_students(students_by_gender)

      # Update the section in the team_distribution
      team_distribution[section] = details
    end
    team_distribution
  end

  # Helper to initialize teams
  def initialize_teams(total_teams)
    Array.new(total_teams) { [] }
  end

  # Helper to get the gender attribute from form responses
  def get_gender_attribute(responses)
    form = Form.find(responses.first.form_id)
    form.form_attributes.find { |attr| attr.name.downcase == "gender" }
  end

  def get_ethnicity_attribute(responses)
    form = Form.find(responses.first.form_id)
    form.form_attributes.find { |attr| attr.name.downcase == "ethnicity" }
  end

  def populate_teams_by_gender_and_minority(teams, categorized_students, minorities, majorities, team_distribution)
    # teams.each_with_index do |team, team_index|
    minorities.each do |minority|
      teams.each_with_index do |team, team_index|
        minority_teams = []
        females = categorized_students[minority]["female"]
        males = categorized_students[minority]["male"]

        if females.size >= 2
          # Take and remove the first two females from categorized_students
          team << females.shift(2)
          minority_teams << team_index
          next
        end

        if females.size == 1
          selected_majority = majorities.sample
          non_minority_female = categorized_students[selected_majority]["female"].shift
          if non_minority_female
            male_in_minority = males.shift if males.any?
            if male_in_minority
              # add 3 of them to a team
              team << [ females.shift, non_minority_female, male_in_minority ].compact
            else
              # shift the non minority female back to the array
              categorized_students[selected_majority]["female"].unshift(non_minority_female)
            end
          else
            teams[minority_teams.sample] << females.shift
          end
        end
      end
    end
    # end
  end









  # Helper to categorize students by gender and calculate weighted average scores
  def categorize_students_by_gender(responses, gender_attribute)
    categorized_students = initialize_categorized_students
    responses.each do |response|
      categorize_student(response, gender_attribute, categorized_students)
    end
    sort_categorized_students(categorized_students)
  end

  private

  def initialize_categorized_students(genders, ethnicities)
    gender_ethnicity_division = outer_keys.each_with_object({}) do |outer_key, outer_map|
      outer_map[outer_key] = inner_keys.each_with_object({}) do |inner_key, inner_map|
        inner_map[inner_key] = []
      end
    end
    gender_ethnicity_division
  end

  def categorize_student(response, gender_attribute, categorized_students)
    student = response.student
    gender_value = response.responses[gender_attribute.id.to_s]
    return if gender_value.nil? || gender_value.strip.empty?

    category = gender_category(gender_value)
    weighted_average = calculate_weighted_average(response)
    categorized_students[category] << { student: student, score: weighted_average } if category
  end

  def gender_category(gender_value)
    case gender_value.downcase
    when "female" then :female
    when "male" then :male
    when "other" then :other
    when "prefer not to say" then :prefer_not_to_say
    end
  end

  def sort_categorized_students(categorized_students)
    categorized_students[:female].sort_by! { |s| -s[:score] }
    categorized_students[:other].sort_by! { |s| -s[:score] }
    categorized_students
  end

  # Helper to distribute female students into teams
  def distribute_female_students(female_students, teams)
    if female_students.size.even?
      assign_pairs_to_teams(female_students, teams)
    else
      assign_pairs_with_remainder(female_students, teams)
    end
  end

  # Helper to assign pairs of female students to teams
  def assign_pairs_to_teams(students, teams)
    team_index = 0
    while students.size > 1 && team_index < teams.size
      # Add the first student from the end of the array
      teams[team_index] << students.pop[:student]

      # Add the last student from the start of the array
      teams[team_index] << students.shift[:student]

      team_index += 1
    end
  end

  # Helper to handle odd-numbered female distribution with 3 remaining students
  def assign_pairs_with_remainder(students, teams)
    i, j, team_index = 0, students.size - 1, 0

    while team_index < teams.size && i <= j
      remaining = j - i + 1

      # Assign three students if exactly three remain
      if remaining == 3
        assign_three_students_to_team(teams[team_index], students, i)
        i += 3  # Move the index forward by 3
      else
        assign_pair_to_team(teams[team_index], students, i, j)
        i += 1  # Move the start index forward
        j -= 1  # Move the end index backward
      end

      team_index += 1
    end

    # Update the students array to reflect removed students
    students.slice!(0...i+1) # Removes assigned students
  end

  def assign_three_students_to_team(team, students, index)
    team << students[index][:student]
    team << students[index + 1][:student]
    team << students[index + 2][:student]
  end

  def assign_pair_to_team(team, students, start_index, end_index)
    team << students[start_index][:student]
    team << students[end_index][:student]
  end




  # Helper to assign one "other" student to teams with 2 or 3 females
  def distribute_other_students(other_students, teams)
    teams.each do |team|
      break if other_students.empty?
      add_student_to_team_if_eligible(team, other_students)
    end
  end

  def add_student_to_team_if_eligible(team, other_students)
    team << other_students.shift[:student] if eligible_for_other_student?(team)
  end

  def eligible_for_other_student?(team)
    team.size >= 2 && team.size < 4
  end

  # Helper to collect all remaining students by gender
  def collect_remaining_students(students_by_gender)
    students_by_gender.values.flatten
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
