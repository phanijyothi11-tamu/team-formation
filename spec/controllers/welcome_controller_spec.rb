RSpec.describe WelcomeController, type: :controller do
    describe "GET #index" do
      context "when user is logged in" do
        let(:user) { create(:user) }

        before do
          allow(controller).to receive(:logged_in?).and_return(true)
          allow(controller).to receive(:current_user).and_return(user)
        end

        it "redirects to the user's page" do
          get :index
          expect(response).to redirect_to(user_path(user))
        end

        it "sets a welcome back notice" do
          get :index
          expect(flash[:notice]).to eq("Welcome, back!")
        end
      end
    end
  end

  RSpec.describe WelcomeController, type: :controller do
    describe "GET #index" do
      context "when user is logged in" do
        let(:user) { create(:user) }

        before do
          allow(controller).to receive(:logged_in?).and_return(true)
          allow(controller).to receive(:current_user).and_return(user)
        end

        it "redirects to the user's page" do
          get :index
          expect(response).to redirect_to(user_path(user))
        end

        it "sets a welcome back notice for the user" do
          get :index
          expect(flash[:notice]).to eq("Welcome, back!")
        end
      end

      context "when student is logged in" do
        let(:student) { create(:student) }

        before do
          allow(controller).to receive(:logged_in?).and_return(true)
          allow(controller).to receive(:current_user).and_return(nil) # Ensure there's no user logged in
          allow(controller).to receive(:current_student).and_return(student)
        end

        it "redirects to the student's page" do
          get :index
          expect(response).to redirect_to(student_path(student))
        end

        it "sets a welcome back notice for the student" do
          get :index
          expect(flash[:notice]).to eq("Welcome back, Student!")
        end
      end
    end
  end
