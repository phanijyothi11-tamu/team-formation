class UsersController < ApplicationController
  def show
    @current_user = User.find(params[:id])
    if @current_user
      # If the user is found, render the user's page (show view)
      render :show
    else
      # If the user is not found, redirect to the welcome page with an error message
      redirect_to welcome_path, alert: "User not found."
    end
  end
end
