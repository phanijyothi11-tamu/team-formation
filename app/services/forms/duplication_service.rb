module Forms
  class DuplicationService < BaseService
    def initialize(original_form)
      @original_form = original_form
    end

    def call
      duplicate_form = @original_form.dup
      duplicate_form.name = generate_copy_name
      duplicate_attributes(duplicate_form)

      if duplicate_form.save
        success(form: duplicate_form)
      else
        failure(form: @original_form, errors: duplicate_form.errors.full_messages)
      end
    end

    private

    def generate_copy_name
      "#{@original_form.name} - Copy"
    end

    def duplicate_attributes(new_form)
      @original_form.form_attributes.each do |attribute|
        new_form.form_attributes << create_duplicate_attribute(attribute)
      end
    end

    def create_duplicate_attribute(attribute)
      attribute.dup.tap do |new_attr|
        new_attr.assign_attributes(
          attribute.attributes.except("id", "created_at", "updated_at", "form_id")
        )
      end
    end
  end
end
