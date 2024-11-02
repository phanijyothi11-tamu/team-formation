module ApplicationHelper
  def bootstrap_class_for(flash_type)
    case flash_type.to_sym
    when :notice then "alert-success"
    when :alert then "alert-warning"
    when :error then "alert-danger"
    else "alert-info"
    end
  end

  def format_deadline(deadline)
    return "No deadline set" if deadline.blank?

    begin
      # Add data attribute for JS and show server-side formatted time
      time = deadline.in_time_zone("America/Chicago")
      content_tag :span, class: "deadline", data: { timestamp: time.iso8601 } do
        time.strftime("%B %d, %Y at %I:%M %p %Z")
      end
    rescue => e
      Rails.logger.error("Error formatting deadline: #{e.message} for deadline: #{deadline.inspect}")
      "Error displaying deadline"
    end
  end
end
