require "rufus-scheduler"

scheduler = Rufus::Scheduler.singleton

# Check every minute
scheduler.every "30s" do
  CheckFormDeadlinesJob.perform_later
end
