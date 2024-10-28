class WelcomeController < ApplicationController
    skip_before_action :require_login, only: [ :index ]
    def index
      if logged_in?
        if current_user
          redirect_to user_path(current_user), notice: "Welcome, back!"
        elsif current_student
          redirect_to student_path(current_student), notice: "Welcome back, Student!"
        end
      else
        render layout: false
        # This will render the welcome page (index view)
        # You can also add any logic to show on the welcome page
      end
    end
end
