class SessionsController < ApplicationController
  skip_before_action :require_login, only: [ :omniauth ]

  # GET /logout
  def logout
    reset_session
    redirect_to welcome_path, notice: "You are logged out."
  end

  # GET /auth/google_oauth2/callback
  def omniauth
    auth = request.env["omniauth.auth"]

    @user = User.find_by(email: auth["info"]["email"])

    if @user
      session[:user_id] = @user.id
      redirect_to user_path(@user), notice: "You are logged in."
    else
      # If user does not exist, redirect to welcome page with an error message
      redirect_to welcome_path, alert: "Login failed: User not found."
    end
  end
end