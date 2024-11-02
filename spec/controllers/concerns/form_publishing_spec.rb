require 'rails_helper'

RSpec.describe FormPublishing, type: :controller do
  # Create a test controller that includes the concern
  controller(ApplicationController) do
    include FormPublishing

    before_action :set_form, only: [ :publish, :close ]

    private

    def set_form
      @form = Form.find(params[:id])
    end
  end

  # Add routes for the anonymous controller
  before do
    routes.draw do
      post 'publish/:id' => 'anonymous#publish', as: :publish
      post 'close/:id' => 'anonymous#close', as: :close
    end
  end

  let(:user) { create(:user) }
  let(:form) { create(:form, user: user, published: false) }

  before do
    session[:user_id] = user.id
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe '#publish' do
    context 'when form can be published' do
      before do
        allow_any_instance_of(Form).to receive(:can_publish?).and_return(true)
      end

      it 'publishes the form successfully' do
        post :publish, params: { id: form.id }
        expect(form.reload.published).to be true
        expect(flash[:notice]).to eq('Form was successfully published.')
        expect(response).to redirect_to(form)
      end

      context 'when update fails' do
        before do
          allow_any_instance_of(Form).to receive(:update).and_return(false)
        end

        it 'redirects with failure message' do
          post :publish, params: { id: form.id }
          expect(form.reload.published).to be false
          expect(flash[:alert]).to eq('Failed to publish the form.')
          expect(response).to redirect_to(form)
        end
      end
    end

    context 'when form cannot be published' do
      before do
        allow_any_instance_of(Form).to receive(:can_publish?).and_return(false)
        allow_any_instance_of(Form).to receive(:has_attributes?).and_return(false)
        allow_any_instance_of(Form).to receive(:has_associated_students?).and_return(false)
      end

      it 'does not publish the form and shows error messages' do
        post :publish, params: { id: form.id }
        expect(form.reload.published).to be false
        expect(flash[:alert]).to eq('Form cannot be published. Reasons: no attributes, no associated students.')
        expect(response).to redirect_to(form)
      end
    end
  end

  describe '#close' do
    let(:published_form) { create(:form, user: user, published: true) }

    context 'when form is successfully closed' do
      it 'closes the form' do
        post :close, params: { id: published_form.id }
        expect(published_form.reload.published).to be false
        expect(flash[:notice]).to eq('Form was successfully closed.')
        expect(response).to redirect_to(published_form)
      end
    end

    context 'when form fails to close' do
      before do
        allow_any_instance_of(Form).to receive(:update).and_return(false)
      end

      it 'shows error message' do
        post :close, params: { id: published_form.id }
        expect(published_form.reload.published).to be true
        expect(flash[:alert]).to eq('Failed to close the form.')
        expect(response).to redirect_to(published_form)
      end
    end
  end
end
