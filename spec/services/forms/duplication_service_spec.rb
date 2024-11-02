require 'rails_helper'

RSpec.describe Forms::DuplicationService do
  let(:user) { create(:user) }
  let(:original_form) { create(:form, user: user, name: "Original Form") }

  describe '.call' do
    it "duplicates a form successfully" do
      result = described_class.call(original_form)

      expect(result.success?).to be true
      expect(result.form.name).to eq("Original Form - Copy")
      expect(result.form.user).to eq(user)
    end

    it "duplicates form attributes" do
      create(:attribute, form: original_form, name: "Test Attribute")
      result = described_class.call(original_form)

      expect(result.success?).to be true
      expect(result.form.form_attributes.count).to eq(1)
      expect(result.form.form_attributes.first.name).to eq("Test Attribute")
    end

    context "when duplication fails" do
      before do
        errors = double(
          full_messages: [ "Name can't be blank" ],
          empty?: false,
          clear: nil,
          add: nil,
          uniq!: nil,
          to_hash: {},
          messages: {},
          details: {}
        )

        failed_form = instance_double(
          Form,
          {
            save: false,
            errors: errors,
            dup: original_form.dup,
            name: "Original Form - Copy",
            "name=": nil,
            form_attributes: [],
            "form_attributes=": nil
          }
        )

        allow(original_form).to receive(:dup).and_return(failed_form)
        allow(original_form).to receive(:form_attributes).and_return([])
      end

      it "returns failure result" do
        result = described_class.call(original_form)

        expect(result.success?).to be false
        expect(result.errors).to include("Name can't be blank")
      end
    end
  end
end
