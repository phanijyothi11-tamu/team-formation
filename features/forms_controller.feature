Feature: Validate file upload
  As a user
  I want to upload a valid file
  So that I can validate the file's content

  Background:
    Given I am logged in as a valid user with a form created
    And I am on the upload page

  Scenario: No file uploaded
    When I submit the upload form without a file
    Then I should see "Please upload a file."
    And I should be redirected to my user profile page

  Scenario: First row is empty
    Given I have uploaded a file with an empty first row
    When I submit the upload form
    Then I should see "The first row is empty. Please provide column names."
    And I should be redirected to my user profile page

  Scenario: Missing required columns
    Given I have uploaded a file without 'Name', 'UIN', and 'Email ID' columns
    When I submit the upload form
    Then I should see "Missing required columns. Ensure 'Name', 'UIN', 'Section' and 'Email ID' are present."
    And I should be redirected to my user profile page

  Scenario: Missing name in a row
    Given I have uploaded a file with missing name in a row
    When I submit the upload form
    Then I should see "Missing value in 'Name' column for row 2."
    And I should be redirected to my user profile page

  Scenario: Invalid UIN format
    Given I have uploaded a file with an invalid UIN in a row
    When I submit the upload form
    Then I should see "Invalid UIN in 'UIN' column for row 2. It must be a 9-digit number."
    And I should be redirected to my user profile page

  Scenario: Missing email in a row
    Given I have uploaded a file with missing email in a row
    When I submit the upload form
    Then I should see "Missing value in 'Email ID' column for row 2."
    And I should be redirected to my user profile page

  Scenario: Invalid email format
    Given I have uploaded a file with an invalid email format in a row
    When I submit the upload form
    Then I should see "Invalid email in 'Email ID' column for row 2."
    And I should be redirected to my user profile page

  Scenario: Valid file upload
    Given I have uploaded a valid file
    When I submit the upload form
    Then I should see "All validations passed."
    And I should be redirected to my user profile page
