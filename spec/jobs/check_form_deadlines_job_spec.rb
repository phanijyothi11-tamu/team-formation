require 'rails_helper'

RSpec.describe CheckFormDeadlinesJob, type: :job do
  describe '#perform' do
    let(:user) { create(:user) }

    it 'unpublishes forms past their deadline' do
      freeze_time do
        # Create forms with very short deadlines
        expired_form = create(:form, user: user, published: true,
                            deadline: 2.seconds.from_now)
        active_form = create(:form, user: user, published: true,
                           deadline: 1.minute.from_now)
        unpublished_form = create(:form, user: user, published: false,
                                deadline: 2.seconds.from_now)

        # Travel forward in time past the deadline
        travel 3.seconds

        described_class.perform_now

        expect(expired_form.reload.published).to be false
        expect(active_form.reload.published).to be true
        expect(unpublished_form.reload.published).to be false
      end
    end
  end
end
