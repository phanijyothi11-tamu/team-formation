module FormPublishing
  extend ActiveSupport::Concern

  def publish
    if @form.can_publish?
      publish_form
    else
      handle_publish_error
    end
  end

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
end
