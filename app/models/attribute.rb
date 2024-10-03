# The Attribute model represents a field or question in a form
class Attribute < ApplicationRecord
  # Associations
  # Each Attribute belongs to a Form
  belongs_to :form

  # Validations
  # Ensure that the name of the attribute is present
  validates :name, presence: true

  # Ensure that the field_type is present and is one of the allowed types
  # text_input: A simple text input field
  # mcq: Multiple Choice Question
  # scale: A numeric scale (e.g., 1-10)
  validates :field_type, presence: true, inclusion: { in: %w[text_input mcq scale] }

  # Custom validations
  # These validations are only run when specific conditions are met

  # Validate the scale range only if the field_type is 'scale'
  validate :validate_scale_range, if: -> { field_type == "scale" }

  # Validate MCQ options only if the field_type is 'mcq'
  validate :validate_mcq_options, if: -> { field_type == "mcq" }

  private

  # Custom validation method for scale fields
  # Ensures that the minimum value is less than the maximum value
  def validate_scale_range
    # Check if both min_value and max_value are present
    if min_value.present? && max_value.present?
      # If min_value is greater than or equal to max_value, add an error
      if min_value >= max_value
        errors.add(:min_value, "must be less than max value")
      end
    end
  end

  # Custom validation method for multiple choice questions (MCQs)
  # Ensures that there are at least two options for an MCQ
  def validate_mcq_options
    # Check if options are present
    if options.present?
      # Split the options string by comma and count the resulting array
      # If the count is less than 2, add an error
      if options.split(",").count < 2
        errors.add(:options, "must have at least two options")
      end
    end
  end
end
