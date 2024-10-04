class Form < ApplicationRecord
  has_many :form_attributes, dependent: :destroy, class_name: "Attribute"
  accepts_nested_attributes_for :form_attributes, allow_destroy: true
end
