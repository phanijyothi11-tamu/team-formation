# This controller handles CRUD operations for Attributes nested under Forms
class AttributesController < ApplicationController
    # This before_action ensures @form is set before any action is executed
    before_action :set_form
    # This before_action sets @attribute only for the destroy action
    before_action :set_attribute, only: [ :destroy, :update_weightage ]

    # POST /forms/:form_id/attributes
    # Creates a new attribute for a specific form
    def create
        @attribute = build_attribute

        if @attribute.save
            redirect_to_form_with_notice("Attribute was successfully added.")
        else
            redirect_to_form_with_alert("Failed to add attribute.")
        end
    end

    def update_weightage
        return redirect_with_error unless weightage_params[:weightage].present?

        new_weightage = calculate_new_weightage
        return redirect_with_total_exceeded_message(new_weightage) if exceeds_total_limit?(new_weightage)

        update_and_redirect
    end

    # DELETE /forms/:form_id/attributes/:id
    # Removes an attribute from a specific form
    def destroy
        if @attribute.destroy
            log_modification("removed", @attribute)
            # If destruction is successful, redirect to the form's edit page with a success notice
            redirect_to edit_form_path(@form), notice: "Attribute was successfully removed."
        else
            # If destruction fails, redirect to the form's edit page with an error alert
            redirect_to edit_form_path(@form), alert: "Failed to remove attribute."
        end
    end

    private

    def log_modification(action, attribute)
        @form = Form.find(params[:form_id])
        modification_details = {
            type: action,
            details: "Attribute '#{attribute.name}' (ID: #{attribute.id})",
            timestamp: Time.current
        }

        @form.modifications ||= {}
        @form.modifications[Time.current.to_s] = modification_details
        @form.save
    end

    # This method finds the parent Form for the nested Attribute
    # It's called by the before_action at the top of the controller
    def set_form
        # Find the form belonging to the current user using the form_id from the URL parameters
        @form = current_user.forms.find(params[:form_id])
    rescue ActiveRecord::RecordNotFound
        # If the form isn't found, redirect to the forms index with an alert
        flash[:alert] = "Form not found"
        redirect_to forms_path
    end

    # This method finds the specific attribute associated with the form
    # It's called by the before_action for the destroy action
    def set_attribute
        # Find the attribute belonging to the form using the id from the URL parameters
        @attribute = @form.form_attributes.find(params[:id])
    rescue ActiveRecord::RecordNotFound
        # If the attribute isn't found, redirect to the form's edit page with an alert
        flash[:alert] = "Attribute not found"
        redirect_to edit_form_path(@form)
    end

    # Strong parameters to prevent mass assignment vulnerabilities
    # This method defines which parameters are allowed when creating or updating an Attribute
    def attribute_params
        params.require(:attribute).permit(:name, :field_type, :min_value, :max_value, :options)
    end

    # def weightage_params
    #     params.require(:attribute).permit(:weightage).tap do |whitelisted|
    #         if whitelisted[:weightage].present?
    #           whitelisted[:weightage] = whitelisted[:weightage].to_f.round(1)
    #           if whitelisted[:weightage] < 0.0 || whitelisted[:weightage] > 1.0
    #             whitelisted[:weightage] = nil
    #           end
    #         end
    #       end
    # end

    def weightage_params
        parsed_weightage = parse_weightage(raw_weightage)
        { weightage: parsed_weightage }
    end

    def redirect_with_error
        redirect_to edit_form_path(@form), alert: "Failed to update weightage."
    end

    def calculate_new_weightage
        current_total = @form.form_attributes.where.not(id: @attribute.id).sum(:weightage)
        new_weightage = weightage_params[:weightage].to_f
        (current_total + new_weightage).round(1)
    end

    def exceeds_total_limit?(total)
        total > 1
    end

    def redirect_with_total_exceeded_message(total)
        redirect_to edit_form_path(@form),
          notice: "Total weightage would be #{total}. Weightages should sum to 1."
    end

    def update_and_redirect
        if @attribute.update(weightage_params)
          log_modification("updated weightage", @attribute)
          redirect_to edit_form_path(@form), notice: "Weightage was successfully updated."
        end
    end


    def raw_weightage
        params.require(:attribute).permit(:weightage)[:weightage]
    end

    def parse_weightage(weightage)
        return nil unless weightage.present?

        parsed_value = weightage.to_f.round(1)
        parsed_value if valid_weightage?(parsed_value)
    end

    def valid_weightage?(value)
        value.between?(0.0, 1.0)
    end

    def build_attribute
        @form.form_attributes.build(attribute_params).tap do |attr|
            set_mcq_options(attr) if mcq_field?
        end
    end

    def mcq_field?
        params[:attribute][:field_type] == "mcq"
    end

    def set_mcq_options(attribute)
        mcq_options = params[:mcq_options].reject(&:blank?)
        attribute.options = mcq_options.join(",") unless mcq_options.empty?
    end

    def redirect_to_form_with_notice(message)
        redirect_to edit_form_path(@form), notice: message
    end

    def redirect_to_form_with_alert(message)
        redirect_to edit_form_path(@form), alert: message
    end
end
