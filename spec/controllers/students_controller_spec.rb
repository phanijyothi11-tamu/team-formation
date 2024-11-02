require 'rails_helper'

RSpec.describe StudentsController, type: :controller do
  let(:student) { create(:student) }

  before do
    allow(controller).to receive(:require_login).and_return(true)
  end

  describe "GET #index" do
    it "assigns all students to @students and renders the index template" do
      get :index
      expect(assigns(:students)).to eq([student])
      expect(response).to render_template(:index)
    end
  end

  describe "GET #show" do
    it "assigns the requested student to @student and renders the show template" do
      get :show, params: { uin: student.id }   # Use id instead of uin
      expect(assigns(:student)).to eq(student)
      expect(response).to render_template(:show)
    end

    it "logs the debug message for the show action" do
      allow(Rails.logger).to receive(:debug)
      get :show, params: { uin: student.id }   # Use id instead of uin
      expect(Rails.logger).to have_received(:debug).with("Rendering show template for student #{student.id}")
    end
  end

  describe "GET #new" do
    it "assigns a new student to @student and renders the new template" do
      get :new
      expect(assigns(:student)).to be_a_new(Student)
      expect(response).to render_template(:new)
    end
  end

  describe "POST #create" do
    context "with valid attributes" do
      it "creates a new student and redirects to the student's show page" do
        expect {
          post :create, params: { student: attributes_for(:student) }
        }.to change(Student, :count).by(1)  # Expect one new student to be created
        expect(response).to redirect_to(student_path(assigns(:student)))  # Redirect to the show page
        expect(flash[:notice]).to eq("Student was successfully created.")  # Check flash message
      end
    end

    context "with invalid attributes" do
      it "does not save the new student and re-renders the new template" do
        expect {
          post :create, params: { student: attributes_for(:student, name: nil) }  # Invalid name
        }.to_not change(Student, :count)  # Expect no new student to be created
        expect(response).to render_template(:new)  # Re-render the new template
      end
    end
  end

  describe "GET #edit" do
    it "assigns the requested student to @student and renders the edit template" do
      get :edit, params: { uin: student.uin }  # Use uin instead of id
      expect(assigns(:student)).to eq(student)
      expect(response).to render_template(:edit)
    end
  end

  describe "PATCH #update" do
    context "with valid attributes" do
      it "updates the student's attributes and redirects to the student's show page" do
        patch :update, params: { uin: student.uin, student: { name: "New Name" } }  # Use uin instead of id
        student.reload  # Reload the student from the database
        expect(student.name).to eq("New Name")  # Check the name was updated
        expect(response).to redirect_to(student_path(student))  # Redirect to the show page
        expect(flash[:notice]).to eq("Student was successfully updated.")  # Check flash message
      end
    end

    context "with invalid attributes" do
      it "does not update the student and re-renders the edit template" do
        patch :update, params: { uin: student.uin, student: { name: nil } }  # Invalid name
        expect(student.reload.name).to_not be_nil  # Ensure the name hasn't changed
        expect(response).to render_template(:edit)  # Re-render the edit template
      end
    end
  end
end
