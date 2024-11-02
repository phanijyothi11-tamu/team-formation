module FormDeadlineManagement
  extend ActiveSupport::Concern

  def update_deadline
    if @form.update(deadline_params)
      redirect_to user_path(@form.user), notice: "Deadline was successfully updated."
    else
      redirect_to user_path(@form.user), alert: "Failed to update the deadline."
    end
  end

  private

  def deadline_params
    params.require(:form).permit(:deadline)
  end
end
