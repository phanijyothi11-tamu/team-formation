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
    before do
      @user = create(:user)  # Ensure you create a user first
      @original_form = create(:form, name: 'Original Form', description: 'This is the original form', user: @user)
      create(:attribute, form: @original_form, name: 'Original Attribute', field_type: 'text_input', min_value: nil, max_value: nil)
    end

    it 'duplicates the form and redirects to the edit page' do
      expect {
        get :duplicate, params: { id: @original_form.id }
      }.to change(Form, :count).by(1)

      duplicated_form = Form.last
      expect(duplicated_form.name).to eq('Original Form - Copy')

      # Access the first attribute and then check its name

      expect(response).to redirect_to(edit_form_path(duplicated_form))
      expect(flash[:notice]).to eq('Form was successfully duplicated.')
    end
  end

  describe '#duplicate failed' do
    before do
      @user = create(:user)
      @original_form = create(:form, name: 'Original Form', description: 'This is the original form', user: @user)
      create(:attribute, form: @original_form, name: 'Original Attribute', field_type: 'text_input')
    end

    context 'when duplication fails due to validation errors' do
      before do
        # Simulate validation failure by setting an invalid attribute
        allow_any_instance_of(Form).to receive(:save).and_return(false)
      end

      it 'redirects back to the edit form with an alert message' do
        post :duplicate, params: { id: @original_form.id }

        expect(response).to redirect_to(edit_form_path(@original_form))
        expect(flash[:alert]).to eq("Failed to duplicate the form.")
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
end