require 'rails_helper'

RSpec.describe StudentsController, type: :controller do
  describe "GET #show" do
    let(:user) { create(:user) }  # Create a user first
    let!(:student) { create(:student) }  # Use let! to ensure student is created before the test runs
    let(:published_form) { create(:form, user: user, published: true) }
    let(:unpublished_form) { create(:form, user: user, published: false) }

    before do
      create(:form_response, student: student, form: published_form)
      create(:form_response, student: student, form: unpublished_form)
    end

    it "assigns the requested student to @student" do
      get :show, params: { id: student.id }
      expect(assigns(:student)).to eq(student)
    end

    it "assigns form_responses including forms to @form_responses" do
      get :show, params: { id: student.id }
      expect(assigns(:form_responses)).to be_present
      expect(assigns(:form_responses).map(&:form)).to include(published_form, unpublished_form)
    end

    it "assigns only published forms to @published_forms" do
      get :show, params: { id: student.id }
      expect(assigns(:published_forms)).to be_present
      expect(assigns(:published_forms)).to include(published_form)
    end

    it "does not assign unpublished forms to @published_forms" do
      get :show, params: { id: student.id }
      expect(assigns(:published_forms)).not_to include(unpublished_form)
    end

    it "renders the show template" do
      get :show, params: { id: student.id }
      expect(response).to render_template(:show)
    end

    # Add this test to check if the student is actually created
    it "creates a student" do
      expect(student).to be_persisted
    end

    # Add this test to check if we can find the student by id
    it "can find the student by id" do
      found_student = Student.find(student.id)
      expect(found_student).to eq(student)
    end
  end
end
