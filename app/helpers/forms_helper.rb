module FormsHelper
  def validate_header(header_row)
    if header_row.nil? || header_row.all?(&:blank?)
      flash[:alert] = "The first row is empty. Please provide column names."
      return false # Indicate failure
    end

    name_index = header_row.index("Name") || -1
    uin_index = header_row.index("UIN") || -1
    email_index = header_row.index("Email ID") || -1
    section_index = header_row.index("Section") || -1

    unless name_index >= 0 && uin_index >= 0 && email_index >= 0 && section_index >= 0
      flash[:alert] = "Missing required columns. Ensure 'Name', 'UIN', 'Section' and 'Email ID' are present."
      return false # Indicate failure
    end

    [ name_index, uin_index, email_index, section_index ] # Return indices if validation passes
  end

  def validate_row(row, index, header_row)
    name_index, uin_index, email_index, section_index = validate_header(header_row)

    return nil if name_index.nil? || uin_index.nil? || email_index.nil? || section_index.nil?

    # Validate Name
    if row[name_index].blank?
      flash[:alert] = "Missing value in 'Name' column for row #{index}."
      return nil
    end

    # Validate Section
    if row[section_index].blank?
      flash[:alert] = "Missing value in 'Section' column for row #{index}."
      return nil
    end

    # Validate UIN
    uin_value = row[uin_index]
    unless valid_uin?(uin_value)
      flash[:alert] = "Invalid UIN in 'UIN' column for row #{index}. It must be a 9-digit number."
      return nil
    end

    # Validate Email
    email_value = row[email_index]
    if email_value.blank?
      flash[:alert] = "Missing value in 'Email ID' column for row #{index}."
      return nil
    end

    unless valid_email?(email_value)
      flash[:alert] = "Invalid email in 'Email ID' column for row #{index}."
      return nil
    end

    # Return user data if all validations pass
    { name: row[name_index], uin: uin_value, email: email_value, section: row[section_index] }
  end



  def valid_uin?(uin_value)
    uin_value.is_a?(String) && uin_value.match?(/^\d{9}$/)
  end

  def valid_email?(email_value)
    email_value =~ /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  end
end
