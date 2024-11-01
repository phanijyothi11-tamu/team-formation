require "jwt"
Rails.application.config.middleware.use OmniAuth::Builder do
    begin
    # Retrieve the Google credentials from Rails credentials
    google_credentials = Rails.application.credentials.google

    # Configure the Google OAuth provider with the client_id and client_secret
    provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"], {
        scope: "email, profile", # This grants access to the user's email and profile information.
        prompt: "select_account", # This allows users to choose the account they want to log in with.
        image_aspect_ratio: "square", # Ensures the profile picture is a square.
        image_size: 50 # Sets the profile picture size to 50x50 pixels.
      }
    rescue => e
        Rails.logger.error "Failed to configure Google OAuth: #{e.message}"
    end
  end
