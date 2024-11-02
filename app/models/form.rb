# The Form model represents a form in the application
# It defines associations with users and attributes, and includes validations
class Form < ApplicationRecord
  # Associations

  # Each form belongs to a user
  # This sets up a one-to-many relationship from User to Form
  belongs_to :user

  # A form can have many attributes (questions/fields)
  # The 'dependent: :destroy' option ensures that when a form is deleted, all its attributes are also deleted
  # 'class_name: "Attribute"' specifies that the associated model is actually called Attribute, not FormAttribute
  has_many :form_attributes, dependent: :destroy, class_name: "Attribute"

  # This allows attributes to be created, updated, or destroyed through the form
  # It's useful for nested forms in views where you want to manage attributes alongside the form
  has_many :form_responses, dependent: :destroy
  has_many :students, through: :form_responses, dependent: :destroy
  accepts_nested_attributes_for :form_attributes, allow_destroy: true

  # Adding the teams association
  has_many :teams, dependent: :destroy

  # Add the published field
  attribute :published, :boolean, default: false

  # Add methods to check for attributes and associated students
  def has_attributes?
    form_attributes.exists?
  end

  def has_associated_students?
    form_responses.exists?
  end

  # Add a method to check if the form can be published
  def can_publish?
    has_attributes? && has_associated_students?
  end

  # Validations

  # Ensures that every form has a name
  # The 'uniqueness: true' option ensures that no two forms can have the same name
  validates :name, presence: true, uniqueness: true

  # Ensures that every form has a description
  validates :description, presence: true

  validate :deadline_cannot_be_in_the_past

  private

  def deadline_cannot_be_in_the_past
    if deadline.present? && deadline < Time.now
      errors.add(:deadline, "cannot be in the past")
    end
  end
end
