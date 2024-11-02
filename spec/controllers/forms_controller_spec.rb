# This file contains RSpec tests for the FormsController
# It covers all CRUD operations (index, show, new, create, edit, update, destroy)
# These tests ensure that forms can be properly managed by authenticated users

require 'rails_helper'

RSpec.describe FormsController, type: :controller do
  let(:user) { create(:user) }
  let(:form) { create(:form, user: user, published: false) }

  before do
    session[:user_id] = user.id
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe "GET #upload" do
    it "returns a success response" do
      get :upload, params: { id: form.id }
      expect(response).to be_successful
    end
  end

  describe "POST #validate_upload" do
    context "when no file is uploaded" do
      it "sets a flash alert and redirects to the user page" do
        post :validate_upload, params: { id: form.id, file: nil }, format: :js
        expect(flash[:alert]).to eq("Please upload a file.")
        expect(response).to redirect_to(edit_form_path(form.id))
      end
    end

    context "when file is uploaded" do
      let(:file) { fixture_file_upload('valid_file.csv', 'text/csv') }

      it "successfully validates the file and creates users" do
        expect {
          post :validate_upload, params: { id: form.id, file: file }
        }.to change(Student, :count).by(1)

        expect(flash[:notice]).to eq("All validations passed.")
      end

      context "when the first row is empty" do
        let(:file) { fixture_file_upload('empty_header.csv', 'text/csv') }

        it "sets a flash alert for empty first row and redirects" do
          post :validate_upload, params: { id: form.id, file: file }
          expect(flash[:alert]).to eq("The first row is empty. Please provide column names.")
        end
      end

      context "when required columns are missing" do
        let(:file) { fixture_file_upload('missing_columns.csv', 'text/csv') }

        it "sets a flash alert for missing columns and redirects" do
          post :validate_upload, params: { id: form.id, file: file }
          expect(flash[:alert]).to eq("Missing required columns. Ensure 'Name', 'UIN', 'Section' and 'Email ID' are present.")
        end
      end

      context "when UIN is invalid" do
        let(:file) { fixture_file_upload('invalid_uin.csv', 'text/csv') }

        it "sets a flash alert for invalid UIN and redirects" do
          post :validate_upload, params: { id: form.id, file: file }
          expect(flash[:alert]).to eq("Invalid UIN in 'UIN' column for row 2. It must be a 9-digit number.")
          expect(response).to redirect_to(edit_form_path(form.id))
        end
      end

      context "when email is missing" do
        let(:file) { fixture_file_upload('missing_email.csv', 'text/csv') }

        it "sets a flash alert for missing email and redirects" do
          post :validate_upload, params: { id: form.id, file: file }
          expect(flash[:alert]).to eq("Missing value in 'Email ID' column for row 2.")
          expect(response).to redirect_to(edit_form_path(form.id))
        end
      end

      context "when email is invalid" do
        let(:file) { fixture_file_upload('invalid_email.csv', 'text/csv') }

        it "sets a flash alert for invalid email and redirects" do
          post :validate_upload, params: { id: form.id, file: file }
          expect(flash[:alert]).to eq("Invalid email in 'Email ID' column for row 2.")
          expect(response).to redirect_to(edit_form_path(form.id))
        end
      end

      context "when a row has missing or invalid data" do
        let(:file) { fixture_file_upload('missing_name.csv', 'text/csv') }

        it "sets a flash alert for missing name and redirects" do
          post :validate_upload, params: { id: form.id, file: file }
          expect(flash[:alert]).to eq("Missing value in 'Name' column for row 2.")
        end
      end
    end
  end

  describe "GET #index" do
    it "returns a success response" do
      # Test if the index action returns a successful response
      get :index
      expect(response).to be_successful
    end

    it "assigns @forms" do
      form # Ensure the form is created
      # Test if the index action assigns the correct forms to @forms
      get :index
      expect(assigns(:forms)).to eq([ form ])
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      # Test if the show action returns a successful response
      get :show, params: { id: form.id }
      expect(response).to be_successful
    end

    it "assigns the requested form to @form" do
      # Test if the show action assigns the correct form to @form
      get :show, params: { id: form.id }
      expect(assigns(:form)).to eq(form)
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      # Test if the new action returns a successful response
      get :new
      expect(response).to be_successful
    end

    it "assigns a new Form to @form" do
      # Test if the new action assigns a new Form object to @form
      get :new
      expect(assigns(:form)).to be_a_new(Form)
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      # Test if the edit action returns a successful response
      get :edit, params: { id: form.id }
      expect(response).to be_successful
    end

    it "assigns the requested form to @form" do
      # Test if the edit action assigns the correct form to @form
      get :edit, params: { id: form.id }
      expect(assigns(:form)).to eq(form)
    end

    it "builds a new form attribute" do
      # Test if the edit action builds a new attribute for the form
      get :edit, params: { id: form.id }
      expect(assigns(:attribute)).to be_a_new(Attribute)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      let(:valid_attributes) { attributes_for(:form) }

      it "creates a new Form" do
        # Test if a new Form is created when valid attributes are provided
        expect {
          post :create, params: { form: valid_attributes }
        }.to change(Form, :count).by(1)
      end

      it "redirects to the edit page of the created form" do
        # Test if the user is redirected to the edit page after form creation
        post :create, params: { form: valid_attributes }
        expect(response).to redirect_to(edit_form_path(Form.last))
      end
    end

    context "with invalid params" do
      let(:invalid_attributes) { attributes_for(:form, name: nil) }

      it "does not create a new Form" do
        # Test if a new Form is not created when invalid attributes are provided
        expect {
          post :create, params: { form: invalid_attributes }
        }.to_not change(Form, :count)
      end

      it "renders the 'new' template" do
        # Test if the new template is rendered when form creation fails
        post :create, params: { form: invalid_attributes }
        expect(response).to render_template("new")
      end
    end

    context "when form params are not nested" do
      let(:valid_attributes) { { name: "Non-nested Form", description: "Description" } }

      it "creates a new Form with non-nested params" do
        # Test if a new Form is created when valid non-nested attributes are provided
        expect {
          post :create, params: valid_attributes
        }.to change(Form, :count).by(1)
      end

      it "redirects to the edit page of the created form" do
        # Test if the user is redirected to the edit page after form creation with non-nested params
        post :create, params: valid_attributes
        expect(response).to redirect_to(edit_form_path(Form.last))
      end
    end

    context "when all form params are missing" do
      it "does not create a new Form" do
        # Test if a new Form is not created when no parameters are provided
        expect {
          post :create, params: {}
        }.not_to change(Form, :count)
      end

      it "renders the 'new' template" do
        # Test if the new template is rendered when no parameters are provided
        post :create, params: {}
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) { { name: "Updated Form Name" } }

      it "updates the requested form" do
        # Test if the form is updated with valid attributes
        put :update, params: { id: form.id, form: new_attributes }
        form.reload
        expect(form.name).to eq("Updated Form Name")
      end

      it "redirects to the form" do
        # Test if the user is redirected to the form page after successful update
        put :update, params: { id: form.id, form: new_attributes }
        expect(response).to redirect_to(form)
      end
    end

    context "with invalid params" do
      let(:invalid_attributes) { { name: nil } }

      it "does not update the form" do
        # Test if the form is not updated with invalid attributes
        put :update, params: { id: form.id, form: invalid_attributes }
        form.reload
        expect(form.name).not_to be_nil
      end

      it "renders the 'edit' template" do
        # Test if the edit template is rendered when form update fails
        put :update, params: { id: form.id, form: invalid_attributes }
        expect(response).to render_template("edit")
      end
    end

    context "when form params are not nested" do
      let(:new_attributes) { { name: "Updated Non-nested Form", description: "New Description" } }

      it "updates the requested form with non-nested params" do
        # Test if the form is updated with valid non-nested attributes
        put :update, params: { id: form.id }.merge(new_attributes)
        form.reload
        expect(form.name).to eq("Updated Non-nested Form")
        expect(form.description).to eq("New Description")
      end

      it "redirects to the form" do
        # Test if the user is redirected to the form page after successful update with non-nested params
        put :update, params: { id: form.id }.merge(new_attributes)
        expect(response).to redirect_to(form)
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested form" do
      # Test if the form is destroyed when the delete action is called
      form_to_delete = create(:form, user: user)
      expect {
        delete :destroy, params: { id: form_to_delete.id }
      }.to change(Form, :count).by(-1)
    end

    it "redirects to the user's show page" do
      # Test if the user is redirected to their show page after form deletion
      delete :destroy, params: { id: form.id }
      expect(response).to redirect_to(user_path(user))
    end
  end

  describe "GET #upload" do
    it "returns a success response" do
      # Test if the upload action returns a successful response
      get :upload, params: { id: form.id }
      expect(response).to be_successful
    end
  end

  describe 'PATCH #update_deadline' do
    context 'with valid deadline' do
      let(:new_deadline) { { deadline: (Time.current + 3.days) } }

      it 'updates the form deadline' do
        patch :update_deadline, params: { id: form.id, form: new_deadline }
        form.reload
        expect(form.deadline.to_i).to eq(new_deadline[:deadline].to_i)
      end

      it 'redirects to the index page with a success message' do
        patch :update_deadline, params: { id: form.id, form: new_deadline }
        expect(response).to redirect_to(user_path(user))
        expect(flash[:notice]).to eq('Deadline was successfully updated.')
      end
    end

    context 'with invalid deadline' do
      let(:invalid_deadline) { { deadline: (Time.current - 1.day) } }

      it 'does not update the form deadline' do
        patch :update_deadline, params: { id: form.id, form: invalid_deadline }
        form.reload
        expect(form.deadline).not_to eq(invalid_deadline[:deadline])
      end

      it 'redirects to the index page with an error message' do
        patch :update_deadline, params: { id: form.id, form: invalid_deadline }
        expect(response).to redirect_to(user_path(user))
        expect(flash[:alert]).to eq('Failed to update the deadline.')
      end
    end
  end

  describe 'GET #preview' do
    before do
      @form = create(:form, name: 'Test Form', description: 'This is a test description')
    end

    it 'renders the preview partial' do
      get :preview, params: { id: @form.id }
      expect(response).to render_template(partial: "_preview")
      expect(assigns(:form)).to eq(@form) # Ensure the correct form is assigned
    end
  end

  describe 'GET #duplicate' do
    let(:original_form) { create(:form, user: user) }

    context "when duplication succeeds" do
      before do
        # Mock the service to return success
        allow(Forms::DuplicationService).to receive(:call)
          .with(original_form)
          .and_return(OpenStruct.new(
            success?: true,
            form: create(:form, user: user, name: "#{original_form.name} - Copy")
          ))
      end

      it "duplicates the form and redirects to the edit page" do
        get :duplicate, params: { id: original_form.id }
        expect(response).to redirect_to(edit_form_path(Form.last))
        expect(flash[:notice]).to eq("Form was successfully duplicated.")
      end
    end

    context "when duplication fails" do
      before do
        # Mock the service to return failure
        allow(Forms::DuplicationService).to receive(:call)
          .with(original_form)
          .and_return(OpenStruct.new(
            success?: false,
            form: original_form,
            errors: [ "Validation failed" ]
          ))
      end

      it "redirects back to the edit form with an alert message" do
        get :duplicate, params: { id: original_form.id }
        expect(response).to redirect_to(edit_form_path(original_form))
        expect(flash[:alert]).to match(/Failed to duplicate the form/)
      end
    end
  end

  describe "POST #publish" do
    it "updates the form to published state when it can be published" do
      allow_any_instance_of(Form).to receive(:can_publish?).and_return(true)

      expect {
        post :publish, params: { id: form.id }
      }.to change { form.reload.published }.from(false).to(true)

      expect(response).to redirect_to(form)
      expect(flash[:notice]).to eq("Form was successfully published.")
    end

    it "does not publish the form and shows an error when it cannot be published" do
      allow_any_instance_of(Form).to receive(:can_publish?).and_return(false)
      allow_any_instance_of(Form).to receive(:has_attributes?).and_return(false)
      allow_any_instance_of(Form).to receive(:has_associated_students?).and_return(false)

      expect {
        post :publish, params: { id: form.id }
      }.not_to change { form.reload.published }

      expect(response).to redirect_to(form)
      expect(flash[:alert]).to eq("Form cannot be published. Reasons: no attributes, no associated students.")
    end
  end

  describe '#calculate_teams' do
    let(:form) { create(:form, user: user) }

    def create_responses(section, count)
      count.times do
        student = create(:student, section: section)
        create(:form_response, form: form, student: student)
      end
    end

    # Helper method to set @form
    def set_form
      controller.instance_variable_set(:@form, form)
    end

    context 'when there are no responses' do
      before { set_form }

      it 'returns an empty hash' do
        result = controller.send(:calculate_teams)
        expect(result).to eq({})
      end
    end

    context 'when there are responses in multiple sections' do
      before do
        create_responses('Section A', 16)
        create_responses('Section B', 14)
        create_responses('Section C', 11)
        set_form
      end

      it 'calculates teams correctly for each section' do
        result = controller.send(:calculate_teams)

        expect(result.keys).to contain_exactly('Section A', 'Section B', 'Section C')

        expect(result['Section A']).to include(
          total_students: 16,
          teams_of_4: 4,
          teams_of_3: 0,
          total_teams: 4
        )

        expect(result['Section B']).to include(
          total_students: 14,
          teams_of_4: 2,
          teams_of_3: 2,
          total_teams: 4
        )

        expect(result['Section C']).to include(
          total_students: 11,
          teams_of_4: 2,
          teams_of_3: 1,
          total_teams: 3
        )
      end

      it 'includes form responses for each section' do
        result = controller.send(:calculate_teams)

        expect(result['Section A'][:form_responses].count).to eq(16)
        expect(result['Section B'][:form_responses].count).to eq(14)
        expect(result['Section C'][:form_responses].count).to eq(11)
      end
    end

    context 'when there are exactly 4 students in a section' do
      before do
        create_responses('Section A', 4)
        set_form
      end

      it 'creates one team of 4' do
        result = controller.send(:calculate_teams)

        expect(result['Section A']).to include(
          total_students: 4,
          teams_of_4: 1,
          teams_of_3: 0,
          total_teams: 1
        )
      end
    end

    context 'when there are 7 students in a section' do
      before do
        create_responses('Section A', 7)
        set_form
      end

      it 'creates one team of 4 and one team of 3' do
        result = controller.send(:calculate_teams)

        expect(result['Section A']).to include(
          total_students: 7,
          teams_of_4: 1,
          teams_of_3: 1,
          total_teams: 2
        )
      end
    end

    context 'when there is a large number of students' do
      before do
        create_responses('Section A', 101)
        set_form
      end

      it 'correctly calculates teams for a large group' do
        result = controller.send(:calculate_teams)

        expect(result['Section A']).to include(
          total_students: 101,
          teams_of_4: 23,
          teams_of_3: 3,
          total_teams: 26
        )
      end
    end
  end

  describe 'POST #close' do
    let(:published_form) { create(:form, user: user, published: true) }

    context 'when the form is successfully closed' do
      it 'updates the form to unpublished' do
        post :close, params: { id: published_form.id }
        expect(published_form.reload.published).to be false
      end

      it 'redirects to the form page' do
        post :close, params: { id: published_form.id }
        expect(response).to redirect_to(published_form)
      end

      it 'sets a success notice' do
        post :close, params: { id: published_form.id }
        expect(flash[:notice]).to eq('Form was successfully closed.')
      end
    end

    context 'when the form fails to close' do
      before do
        allow_any_instance_of(Form).to receive(:update).and_return(false)
      end

      it 'does not update the form' do
        post :close, params: { id: published_form.id }
        expect(published_form.reload.published).to be true
      end

      it 'redirects to the form page' do
        post :close, params: { id: published_form.id }
        expect(response).to redirect_to(published_form)
      end

      it 'sets an alert message' do
        post :close, params: { id: published_form.id }
        expect(flash[:alert]).to eq('Failed to close the form.')
      end
    end
  end

  describe '#populate_teams_based_on_gender' do
    let(:user) { create(:user) }
    let!(:form) { create(:form, name: "Team Formation Form", description: "Form for collecting team preferences", user: user) }
    let!(:gender_attr) { form.form_attributes.create!(name: "Gender", field_type: "mcq", options: "male,female,other,prefer not to say") }
    let!(:sections) { [ "A", "B" ] }

    # Helper method to set @form
    def set_form
      controller.instance_variable_set(:@form, form)
    end

    # Helper method to create students and responses for the test
    def create_responses(section, gender_distribution)
      gender_distribution.each do |gender, count|
        count.times do
          student = create(:student, section: section)
          create(:form_response, form: form, student: student, responses: { gender_attr.id.to_s => gender })
        end
      end
    end

    before do
      set_form
      # Creating gender-distributed students in each section
      create_responses("A", { "female" => 6, "male" => 4, "other" => 2, "prefer not to say" => 2 })
      create_responses("B", { "female" => 5, "male" => 3, "other" => 2, "prefer not to say" => 1 })
    end

    it 'distributes students into teams based on gender correctly' do
      # Initial team distribution setup
      team_distribution = {
        "A" => {
          total_students: 14,
          teams_of_4: 2,
          teams_of_3: 2,
          total_teams: 4,
          form_responses: form.form_responses.joins(:student).where(students: { section: "A" })
        },
        "B" => {
          total_students: 15,
          teams_of_4: 2,
          teams_of_3: 1,
          total_teams: 3,
          form_responses: form.form_responses.joins(:student).where(students: { section: "B" })
        }
      }

      updated_distribution = controller.send(:populate_teams_based_on_gender, team_distribution)

      # Verify that updated_distribution has the same attributes as team_distribution for each section
      team_distribution.each do |section, details|
        expect(updated_distribution[section][:total_students]).to eq(details[:total_students])
        expect(updated_distribution[section][:teams_of_4]).to eq(details[:teams_of_4])
        expect(updated_distribution[section][:total_teams]).to eq(details[:total_teams])
        expect(updated_distribution[section][:form_responses]).to match_array(details[:form_responses])
      end

      def student_gender(student_id)
        return "unassigned" if student_id.zero?

        form_response = form.form_responses.find_by(student_id: student_id)
        form_response.responses[gender_attr.id.to_s] if form_response
      end

      # Validate team distribution for section B
      section_b = updated_distribution["B"]
      expected_b_team_genders = [
        { female: 2, male: 0, other: 1, prefer_not_to_say: 0 },
        { female: 3, male: 0, other: 1, prefer_not_to_say: 0 },
        { female: 0, male: 0, other: 0, prefer_not_to_say: 0 }
      ]

      section_b[:teams].each_with_index do |team, index|
        genders = team.map { |student_id| student_gender(student_id) }
        expect(genders.count('female')).to eq(expected_b_team_genders[index][:female])
        expect(genders.count('male')).to eq(expected_b_team_genders[index][:male])
        expect(genders.count('other')).to eq(expected_b_team_genders[index][:other])
        expect(genders.count('prefer not to say')).to eq(expected_b_team_genders[index][:prefer_not_to_say])
      end

      # Validate team distribution for section A
      section_a = updated_distribution["A"]
      expected_a_team_genders = [
        { female: 2, male: 0, other: 1, prefer_not_to_say: 0 },
        { female: 2, male: 0, other: 1, prefer_not_to_say: 0 },
        { female: 2, male: 0, other: 0, prefer_not_to_say: 0 },
        { female: 0, male: 0, other: 0, prefer_not_to_say: 0 }
      ]

      section_a[:teams].each_with_index do |team, index|
        expect(team.size).to be_between(3, 4)
        genders = team.map { |student_id| student_gender(student_id) }
        expect(genders.count('female')).to eq(expected_a_team_genders[index][:female])
        expect(genders.count('male')).to eq(expected_a_team_genders[index][:male])
        expect(genders.count('other')).to eq(expected_a_team_genders[index][:other])
        expect(genders.count('prefer not to say')).to eq(expected_a_team_genders[index][:prefer_not_to_say])
      end
    end
  end
  describe 'POST #generate_teams' do
    let(:user) { create(:user) }
    let(:form) { create(:form, user: user) }
    let(:students) { create_list(:student, 8) }  # Create 8 students without specifying IDs
    let(:team_distribution) do
      {
        'Section A' => {
          teams: [
            students[0..3].map(&:id),  # First team of 4
            students[4..7].map(&:id)   # Second team of 4
          ]
        }
      }
    end

    before do
      allow(controller).to receive(:calculate_teams).and_return(team_distribution)
      allow(controller).to receive(:populate_teams_based_on_gender).and_return(team_distribution)
      allow(controller).to receive(:optimize_teams_based_on_ethnicity).and_return(team_distribution)
      allow(controller).to receive(:distribute_remaining_students).and_return(team_distribution)
      allow(controller).to receive(:optimize_team_by_swaps).and_return(team_distribution)

      # Create form responses for each student
      students.each do |student|
        create(:form_response, form: form, student: student)
      end
    end

    it 'generates teams successfully' do
      expect {
        post :generate_teams, params: { id: form.id }
      }.to change(Team, :count).by(2)

      expect(response).to redirect_to(view_teams_form_path(form))
      expect(flash[:notice]).to eq("Teams have been successfully generated!")
    end

    it 'calls populate_teams_based_on_gender' do
      expect(controller).to receive(:populate_teams_based_on_gender).and_return(team_distribution)
      post :generate_teams, params: { id: form.id }
    end

    it 'creates teams with correct attributes' do
      post :generate_teams, params: { id: form.id }

      created_teams = form.teams.reload
      expect(created_teams.count).to eq(2)
      expect(created_teams.first.name).to eq("Team 1")
      expect(created_teams.first.section).to eq("Section A")
      expect(created_teams.first.members).to be_an(Array)
      expect(created_teams.first.members.count).to eq(4)
    end

    it 'handles errors during team generation' do
      allow(controller).to receive(:calculate_teams).and_raise(StandardError, "Test error")

      expect {
        post :generate_teams, params: { id: form.id }
      }.to raise_error(StandardError, "Test error")

      expect(Team.count).to eq(0)
    end
  end
  describe "GET #export_teams" do
    let(:form_with_teams) { create(:form, user: user) }
    let!(:team) { create(:team, form: form_with_teams) }

    before do
      allow(controller).to receive(:current_user).and_return(user)
    end

    context "when there are teams to export" do
      it "exports teams in Excel format" do
        get :export_teams, params: { id: form_with_teams.id, format: :xlsx }
        expect(response.content_type).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
        expect(response.headers['Content-Disposition']).to include('attachment; filename="teams.xlsx"')
      end

      it "exports teams in CSV format" do
        get :export_teams, params: { id: form_with_teams.id, format: :csv }
        expect(response.content_type).to eq('text/csv')
        expect(response.headers['Content-Disposition']).to include('attachment; filename="teams-')
      end

      it "exports teams in PDF format" do
        get :export_teams, params: { id: form_with_teams.id, format: :pdf }
        expect(response.content_type).to eq('application/pdf')
        expect(response.headers['Content-Disposition']).to include('attachment; filename="teams-')
      end
    end

    context "when there are no teams to export" do
      let(:form_without_teams) { create(:form, user: user) }

      it "redirects to view teams page with an alert" do
        get :export_teams, params: { id: form_without_teams.id, format: :xlsx }
        expect(response).to redirect_to(view_teams_form_path(form_without_teams))
        expect(flash[:alert]).to eq('No teams available for export.')
      end
    end
  end

  describe "#generate_csv" do
    let(:user) { create(:user) }
    let(:form) { create(:form, user: user) }
    let(:team) { create(:team, form: form, name: "Team 1", section: "Section A") }
    let!(:student) { create(:student) }

    before do
      @member_data = {
        "id" => student.id,
        "name" => student.name,
        "uin" => student.uin,
        "email" => student.email
      }
      team.members = [ @member_data ]
      team.save!

      # Force reloading to ensure data is persisted
      @team = team.reload
    end

    it "generates a CSV with correct headers and data structure" do
      csv_data = controller.send(:generate_csv, [ @team ])
      csv_lines = csv_data.split("\n")

      expect(csv_lines[0]).to eq("Section,Team Name,Student Name,UIN,Email")

      data_line = CSV.parse(csv_lines[1]).first

      expect(data_line[0]).to eq("Section A")
      expect(data_line[1]).to eq("Team 1")
      expect(data_line[2]).to eq(@member_data["name"])
      expect(data_line[3]).to eq(@member_data["uin"])
      expect(data_line[4]).to eq(@member_data["email"])
    end
end
end
