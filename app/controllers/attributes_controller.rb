# This controller handles CRUD operations for Attributes nested under Forms
class AttributesController < ApplicationController
    # This before_action ensures @form is set before any action is executed
    before_action :set_form
    before_action :set_attribute, only: [:destroy]

    # POST /forms/:form_id/attributes
    def create
        # Build a new attribute associated with the current form
        # form_attributes is the association name we defined in the Form model
        @attribute = @form.form_attributes.build(attribute_params)

        if @attribute.save
            # If save is successful, respond accordingly
            redirect_to edit_form_path(@form), notice: "Attribute was successfully added."
        else
            redirect_to edit_form_path(@form), alert: "Failed to add attribute."
        end
    end

    # DELETE /forms/:form_id/attributes/:id
    def destroy
        if @attribute.destroy
            redirect_to edit_form_path(@form), notice: "Attribute was successfully removed."
        else
            redirect_to edit_form_path(@form), alert: "Failed to remove attribute."
        end
    end

    private

    # This method finds the parent Form for the nested Attribute
    # It's called by the before_action at the top of the controller
    def set_form
        @form = Form.find(params[:form_id])
    rescue ActiveRecord::RecordNotFound
        # If the form isn't found, redirect to the forms index with an alert
        flash[:alert] = "Form not found"
        redirect_to forms_path
    end

    # This method finds the specific attribute associated with the form
    def set_attribute
        @attribute = @form.form_attributes.find(params[:id])
    rescue ActiveRecord::RecordNotFound
        flash[:alert] = "Attribute not found"
        redirect_to edit_form_path(@form)
    end

    # Strong parameters to prevent mass assignment vulnerabilities
    # This method defines which parameters are allowed when creating or updating an Attribute
    def attribute_params
        params.require(:attribute).permit(:name, :field_type, :min_value, :max_value, :options)
    end
end
