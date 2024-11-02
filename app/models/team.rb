class Team < ApplicationRecord
  belongs_to :form

  validates :members, presence: true
  validates :section, presence: true
  validates :name, presence: true

  # Use the modern Rails attribute API for JSON serialization
  attribute :members, :json, default: []

  # # Helper method to get student objects for team members
  # def student_members
  #   Student.where(id: members.map { |m| m["id"] })
  # end

  # # Get the size of the team
  # def size
  #   members.size
  # end

  # # Get member names as a comma-separated string
  # def member_names
  #   members.map { |m| m["name"] }.join(", ")
  # end

  # # Get member UINs as a comma-separated string
  # def member_uins
  #   members.map { |m| m["uin"] }.join(", ")
  # end

  # # Get member emails as a comma-separated string
  # def member_emails
  #   members.map { |m| m["email"] }.join(", ")
  # end
end
