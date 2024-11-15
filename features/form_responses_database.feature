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
    Given I login as a professor
    And I have published a form "Access Form"
    And I have uploaded a list of students to a form
    And the eligible list contains student_id "[3]" and not "[4]"
    When "student4" logs into the system
    Then the student should not see "Access Form"
