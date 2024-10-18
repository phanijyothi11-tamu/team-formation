class StudentsController < ApplicationController
  skip_before_action :require_login, only: [ :show ]

  def index
    @students = Student.all
  end

  def show
    @student = Student.find(params[:id])
    @form_responses = @student.form_responses.includes(:form)
    @published_forms = @form_responses.map(&:form).select(&:published?).uniq
    # Add this line for debugging
    Rails.logger.debug "Rendering show template for student #{@student.id}"
  end

  def new
    @student = Student.new
  end

  def create
    @student = Student.new(student_params)
    if @student.save
      redirect_to @student, notice: "Student was successfully created."
    else
      render :new
    end
  end

  def edit
    @student = Student.find_by(uin: params[:uin])
  end

  def update
    @student = Student.find_by(uin: params[:uin])
    if @student.update(student_params)
      redirect_to @student, notice: "Student was successfully updated."
    else
      render :edit
    end
  end

  private

  def student_params
    params.require(:student).permit(:uin, :name, :email, :section)
  end
end
