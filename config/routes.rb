Rails.application.routes.draw do
  # Student routes with nested form_responses using `uin` as the primary identifier
  resources :students, param: :uin do
    resources :form_responses, only: [:index]
    # This allows us to view all form responses for a specific student
    # GET /students/:uin/form_responses
  end

  resources :forms do
    member do
      get "preview"
      get "duplicate"
      patch "update_deadline"
      post "publish"
      post "close"
      get "upload", to: "forms#upload", as: :upload
      post "validate_upload", to: "forms#validate_upload"
      post :generate_teams
      get :view_teams
      get :export_teams
    end

    resources :attributes do
      member do
        patch :update_weightage
      end
    end

    resources :form_responses, only: [:index]
    # This allows us to view all form responses for a specific form
    # GET /forms/:form_id/form_responses
  end

  # Standalone form_responses resource for CRUD operations
  resources :form_responses, only: [:index, :show, :new, :create, :edit, :update, :destroy]
  # This sets up the following routes:
  # GET    /form_responses/:id          - show a specific form response
  # GET    /form_responses/new          - display form for creating a new form response
  # POST   /form_responses              - create a new form response
  # GET    /form_responses/:id/edit     - display form for editing an existing form response
  # PATCH  /form_responses/:id          - update an existing form response
  # DELETE /form_responses/:id          - delete a form response

  # Custom routes for creating form responses
  # These routes explicitly show the relationship between forms, students, and form responses
  get "/forms/:form_id/students/:uin/form_responses/new",
      to: "form_responses#new",
      as: "new_form_student_form_response"
  # This route is used to display the form for creating a new form response
  # It includes both form_id and uin to associate the response with both entities
  # GET /forms/:form_id/students/:uin/form_responses/new

  post "/forms/:form_id/students/:uin/form_responses",
       to: "form_responses#create",
       as: "form_student_form_responses"
  # This route is used to submit the form and create a new form response
  # It also includes both form_id and uin to create the proper associations
  # POST /forms/:form_id/students/:uin/form_responses

  # Defines the root path route ("/")
  root "welcome#index"
  get "welcome/index", to: "welcome#index", as: "welcome"
  get "/users/:id", to: "users#show", as: "user"
  get "/logout", to: "sessions#logout", as: "logout"
  get "/auth/google_oauth2/callback", to: "sessions#omniauth"

  # Session routes
  get "sessions/logout"
  get "sessions/omniauth"
  get "users/show"

  # Health status check
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA routes
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "/forms/:form_id/upload", to: "forms#upload"
  post "/forms/:form_id/validate_upload", to: "forms#validate_upload"
end
