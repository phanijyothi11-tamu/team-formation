source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.2"
# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"
# Use Redis adapter to run Action Cable in production
# gem "redis", ">= 4.0.1"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false
# gems for the SSO
# omniauth for google login
gem "omniauth", "~> 2.1.1"
gem "omniauth-google-oauth2", "~> 1.1.1"
gem "omniauth-oauth2", "~> 1.8.0"
gem "omniauth-rails_csrf_protection", "~> 1.0.1"
gem "jwt", "~> 2.7.1"


gem "devise"
gem "roo", "~> 2.10.0"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false
  gem "factory_bot_rails"

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  gem "rubocop", require: false
  gem "rubocop-rspec", require: false

  # RSpec for Rails
  gem "rspec-rails", "~> 6.0"

  # Cucumber for acceptance testing
  gem "cucumber-rails", require: false

  # Database cleaner for testing
  gem "database_cleaner"

  # SimpleCov for code coverage
  gem "simplecov", require: false


  # Faker for generating fake data in tests
  gem "faker"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
  # Use sqlite3 as the database for Active Record
end

group :test do
  gem "capybara"
  gem "database_cleaner-active_record"
  gem "selenium-webdriver"
  gem "webdrivers"
  gem "rack_session_access"
  gem "shoulda-matchers"
  gem "rails-controller-testing"
end

group :development, :test do
  gem "sqlite3"
end


group :production do
  gem "pg"
end

gem "csv"

group :development, :test do
  gem "rubocop"
  gem "rubocop-rspec"
end

gem "rufus-scheduler"
gem "rubyzip"
gem "axlsx"
gem "caxlsx_rails"
gem "wicked_pdf"
gem "wkhtmltopdf-binary"
