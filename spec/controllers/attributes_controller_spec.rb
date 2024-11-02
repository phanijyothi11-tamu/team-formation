  # This file contains RSpec tests for the AttributesController
  # It covers the creation and deletion of form attributes
  # These tests ensure that form attributes can be properly managed within the context of a form

  require 'rails_helper'

RSpec.describe AttributesController, type: :controller do
  # Create test data using FactoryBot
  let(:user) { create(:user) }
  let(:form) { create(:form, user: user) }
  let(:valid_attributes) { attributes_for(:attribute) }
  let(:invalid_attributes) { attributes_for(:attribute, name: nil) }

  before do
    # Simulate a logged-in user for all tests
    session[:user_id] = user.id
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Attribute" do
        expect {
          post :create, params: { form_id: form.id, attribute: valid_attributes }
        }.to change(Attribute, :count).by(1)
      end

      it "associates the new Attribute with the correct Form" do
        post :create, params: { form_id: form.id, attribute: valid_attributes }
        expect(Attribute.last.form).to eq(form)
      end

      it "sets the options for an MCQ attribute" do
        mcq_attributes = valid_attributes.merge(field_type: "mcq")
        post :create, params: { form_id: form.id, attribute: mcq_attributes, mcq_options: [ "Option 1", "Option 2" ] }
        expect(Attribute.last.options).to eq("Option 1,Option 2")
      end

      it "redirects to the form edit page" do
        post :create, params: { form_id: form.id, attribute: valid_attributes }
        expect(response).to redirect_to(edit_form_path(form))
      end

      it "sets a success notice" do
        post :create, params: { form_id: form.id, attribute: valid_attributes }
        expect(flash[:notice]).to eq("Attribute was successfully added.")
      end
    end

    context "with invalid params" do
      it "does not create a new Attribute" do
        expect {
          post :create, params: { form_id: form.id, attribute: invalid_attributes }
        }.to_not change(Attribute, :count)
      end

      it "redirects to the form edit page" do
        post :create, params: { form_id: form.id, attribute: invalid_attributes }
        expect(response).to redirect_to(edit_form_path(form))
      end

      it "sets an alert message" do
        post :create, params: { form_id: form.id, attribute: invalid_attributes }
        expect(flash[:alert]).to eq("Failed to add attribute.")
      end
    end
  end

  describe "DELETE #destroy" do
    # Create an attribute for testing deletion
    let!(:attribute) { create(:attribute, form: form) }

    it "destroys the requested attribute" do
      # Expect the Attribute count to decrease by 1 when we delete an attribute
      expect {
        delete :destroy, params: { form_id: form.id, id: attribute.id }
      }.to change(Attribute, :count).by(-1)
    end

    it "redirects to the form edit page" do
      # After deleting an attribute, we should be redirected to the form's edit page
      delete :destroy, params: { form_id: form.id, id: attribute.id }
      expect(response).to redirect_to(edit_form_path(form))
    end

    it "sets a success notice" do
      # Check if a success message is set in the flash after deletion
      delete :destroy, params: { form_id: form.id, id: attribute.id }
      expect(flash[:notice]).to eq("Attribute was successfully removed.")
    end

    context "when attribute doesn't exist" do
      it "redirects to the form edit page" do
        # When trying to delete a non-existent attribute, we should still be redirected to the form's edit page
        delete :destroy, params: { form_id: form.id, id: 9999 }
        expect(response).to redirect_to(edit_form_path(form))
      end

      it "sets an alert message" do
        # Check if an alert message is set when trying to delete a non-existent attribute
        delete :destroy, params: { form_id: form.id, id: 9999 }
        expect(flash[:alert]).to eq("Attribute not found")
      end
    end

    context "when attribute fails to be destroyed" do
      before do
        # Simulate a scenario where the attribute fails to be destroyed
        allow_any_instance_of(Attribute).to receive(:destroy).and_return(false)
      end

      it "redirects to the form edit page with an alert" do
        # When attribute destruction fails, we should be redirected with an alert
        delete :destroy, params: { form_id: form.id, id: attribute.id }
        expect(response).to redirect_to(edit_form_path(form))
        expect(flash[:alert]).to eq("Failed to remove attribute.")
      end
    end
  end

  describe "Error handling" do
    context "when form doesn't exist" do
      it "redirects to forms index" do
        # When trying to create an attribute for a non-existent form, we should be redirected to the forms index
        post :create, params: { form_id: 9999, attribute: valid_attributes }
        expect(response).to redirect_to(forms_path)
      end

      it "sets an alert message" do
        # Check if an alert message is set when trying to use a non-existent form
        post :create, params: { form_id: 9999, attribute: valid_attributes }
        expect(flash[:alert]).to eq("Form not found")
      end
    end
  end

  describe "PATCH #update_weightage" do
  let!(:attribute) { create(:attribute, form: form, weightage: 0.5) }

  context "with valid params" do
    it "updates the weightage" do
      patch :update_weightage, params: { form_id: form.id, id: attribute.id, attribute: { weightage: 0.8 } }
      attribute.reload
      expect(attribute.weightage).to eq(0.8)
    end

    it "redirects to the form edit page" do
      patch :update_weightage, params: { form_id: form.id, id: attribute.id, attribute: { weightage: 0.8 } }
      expect(response).to redirect_to(edit_form_path(form))
    end

    it "sets a success notice" do
      patch :update_weightage, params: { form_id: form.id, id: attribute.id, attribute: { weightage: 0.8 } }
      expect(flash[:notice]).to eq("Weightage was successfully updated.")
    end
  end

  context "when total weightage would exceed 1" do
    let!(:another_attribute) { create(:attribute, form: form, weightage: 0.4) }

    it "does not update the weightage" do
      expect {
        patch :update_weightage, params: { form_id: form.id, id: attribute.id, attribute: { weightage: 0.7 } }
      }.not_to change { attribute.reload.weightage }
    end

    it "redirects to the form edit page" do
      patch :update_weightage, params: { form_id: form.id, id: attribute.id, attribute: { weightage: 0.7 } }
      expect(response).to redirect_to(edit_form_path(form))
    end

    it "sets a notice about exceeding total weightage" do
      patch :update_weightage, params: { form_id: form.id, id: attribute.id, attribute: { weightage: 0.7 } }
      expect(flash[:notice]).to include("Total weightage would be")
      expect(flash[:notice]).to include("Weightages should sum to 1")
    end
  end

  context "with invalid params" do
    it "does not update the weightage if out of range" do
      expect {
        patch :update_weightage, params: { form_id: form.id, id: attribute.id, attribute: { weightage: 1.5 } }
      }.not_to change { attribute.reload.weightage }
    end

    it "redirects to the form edit page" do
      patch :update_weightage, params: { form_id: form.id, id: attribute.id, attribute: { weightage: 1.5 } }
      expect(response).to redirect_to(edit_form_path(form))
    end

    it "sets an alert message for invalid weightage" do
      patch :update_weightage, params: { form_id: form.id, id: attribute.id, attribute: { weightage: -0.1 } }
      expect(flash[:alert]).to eq("Failed to update weightage.")
    end
  end

  context "when attribute doesn't exist" do
    it "redirects to the form edit page" do
      patch :update_weightage, params: { form_id: form.id, id: 9999, attribute: { weightage: 0.8 } }
      expect(response).to redirect_to(edit_form_path(form))
    end

    it "sets an alert message" do
      patch :update_weightage, params: { form_id: form.id, id: 9999, attribute: { weightage: 0.8 } }
      expect(flash[:alert]).to eq("Attribute not found")
    end
  end
end

describe "Helper methods" do
  describe "#build_attribute" do
    it "builds a regular attribute" do
      post :create, params: {
        form_id: form.id,
        attribute: valid_attributes.merge(field_type: "text")
      }
      expect(assigns(:attribute)).to be_a(Attribute)
      expect(assigns(:attribute).field_type).to eq("text")
    end

    it "builds an MCQ attribute with options" do
      post :create, params: {
        form_id: form.id,
        attribute: valid_attributes.merge(field_type: "mcq"),
        mcq_options: [ "Option 1", "", "Option 2" ]  # Including a blank option
      }
      expect(assigns(:attribute).options).to eq("Option 1,Option 2")
    end
  end

  describe "weightage handling" do
    let(:attribute) { create(:attribute, form: form, weightage: 0.3) }

    describe "#calculate_new_weightage" do
      it "correctly calculates total weightage" do
        # Create another attribute to test total calculation
        create(:attribute, form: form, weightage: 0.3)

        # We need to set up the controller instance variables
        controller.instance_variable_set(:@form, form)
        controller.instance_variable_set(:@attribute, attribute)

        # Make calculate_new_weightage accessible for testing
        allow(controller).to receive(:params).and_return(
          ActionController::Parameters.new(
            attribute: { weightage: "0.7" }
          )
        )

        # Test the actual calculation
        result = controller.send(:calculate_new_weightage)
        expect(result).to eq(1.0)
      end
    end

    describe "#parse_weightage" do
      # Make the method public for testing
      before do
        AttributesController.send(:public, :parse_weightage)
      end

      after do
        AttributesController.send(:private, :parse_weightage)
      end

      it "returns nil for blank weightage" do
        expect(controller.parse_weightage("")).to be_nil
      end

      it "rounds to one decimal place" do
        expect(controller.parse_weightage("0.666")).to eq(0.7)
      end

      it "returns nil for invalid weightages" do
        expect(controller.parse_weightage("-0.1")).to be_nil
        expect(controller.parse_weightage("1.1")).to be_nil
      end
    end

    describe "#valid_weightage?" do
      before do
        AttributesController.send(:public, :valid_weightage?)
      end

      after do
        AttributesController.send(:private, :valid_weightage?)
      end

      it "accepts values between 0 and 1" do
        expect(controller.valid_weightage?(0.0)).to be true
        expect(controller.valid_weightage?(1.0)).to be true
        expect(controller.valid_weightage?(0.5)).to be true
      end

      it "rejects values outside 0-1 range" do
        expect(controller.valid_weightage?(-0.1)).to be false
        expect(controller.valid_weightage?(1.1)).to be false
      end
    end
  end

  describe "redirect helpers" do
    let(:attribute) { create(:attribute, form: form) }

    before do
      # Set up controller instance variables
      controller.instance_variable_set(:@form, form)
    end

    it "redirects with notice" do
      expect(controller).to receive(:redirect_to).with(
        edit_form_path(form),
        { notice: "Test notice" }
      )
      controller.send(:redirect_to_form_with_notice, "Test notice")
    end

    it "redirects with alert" do
      expect(controller).to receive(:redirect_to).with(
        edit_form_path(form),
        { alert: "Test alert" }
      )
      controller.send(:redirect_to_form_with_alert, "Test alert")
    end

    it "redirects with total exceeded message" do
      expect(controller).to receive(:redirect_to).with(
        edit_form_path(form),
        { notice: "Total weightage would be 1.2. Weightages should sum to 1." }
      )
      controller.send(:redirect_with_total_exceeded_message, 1.2)
    end
  end

  describe "#update_and_redirect" do
    let(:attribute) { create(:attribute, form: form) }

    before do
      # Set up controller instance variables
      controller.instance_variable_set(:@form, form)
      controller.instance_variable_set(:@attribute, attribute)

      # Mock the params for weightage_params
      allow(controller).to receive(:params).and_return(
        ActionController::Parameters.new(
          attribute: { weightage: "0.5" }
        )
      )
    end

    it "updates weightage and redirects with success message" do
      # Change the expectation to match how update is actually called
      expect(attribute).to receive(:update).with({ weightage: 0.5 }).and_return(true)
      expect(controller).to receive(:redirect_to).with(
        edit_form_path(form),
        { notice: "Weightage was successfully updated." }
      )

      controller.send(:update_and_redirect)
    end
  end
end
end
