Feature: Form Responses
  As a professor,
  So that student information can be considered for team formation,
  I want student details to get saved in the database.

  Scenario: Store student responses in the database table
    Given I am logged in as a professor
    And I have created a form
    And I have added the following attributes to the form:
      | Name                   | Field Type    | Options                     | Min Value | Max Value |
      | Programming Experience | text_input    |                             |           |           |
      | Preferred Role         | mcq           | Developer,Tester,Designer   |           |           |
      | Teamwork Skills        | scale         |                             | 1         | 5         |
    And I have uploaded a list of eligible students for the form
    When an eligible student submits their responses
      | Attribute Name           | Response               |
      | Programming Experience   | 3 years of experience  |
      | Preferred Role           | Developer              |
      | Teamwork Skills          | 4                      |
    Then the response should be stored in the form_responses table
    And I should see a confirmation message "Response submitted successfully."

  Scenario: Ineligible student attempts to access the form
    Given I am logged in as a professor
    And I have created a form
    And I have uploaded a list of eligible students for the form
    When an ineligible student attempts to access the form
    Then they should see an error message "You are not eligible to access this form."
