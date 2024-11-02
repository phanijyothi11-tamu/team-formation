class CheckFormDeadlinesJob < ApplicationJob
  queue_as :default

  def perform
    Form.where(published: true)
        .where("deadline < ?", Time.current)
        .update_all(published: false)
  end
end
