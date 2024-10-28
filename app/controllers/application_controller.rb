# This is the base controller that all other controllers inherit from
# It handles user authentication and provides helper methods for user sessions
class ApplicationController < ActionController::Base
  # Include necessary modules and set up before actions
  before_action :require_login
  helper_method :current_user, :current_student, :logged_in?

  private

  # Method to get the current user
  def current_user
    # Memoization: store the result in an instance variable to avoid repeated database queries
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
    # This method returns the current user if they're logged in, or nil if not
  end
  def current_student
    # Memoization: store the result in an instance variable to avoid repeated database queries
    @current_student ||= Student.find_by(id: session[:student_id]) if session[:student_id]
    # This method returns the current user if they're logged in, or nil if not
  end

  # Method to check if a user is logged in
  def logged_in?
    # Double bang (!!) converts the result to a boolean
    # Returns true if current_user is not nil, false otherwise
    !!current_user || !!current_student
  end

  # Method to require login for certain actions
  def require_login
    unless logged_in?
      # If the user is not logged in, redirect to the welcome page
      # and set a flash alert message
      redirect_to welcome_path, alert: "You must be logged in to access this section."
    end
  end
end
