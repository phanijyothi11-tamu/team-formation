Feature: Form Responses
    Given there is a published form
    Given there is a logged student
    Given associated Form response
  Scenario: Creating a new form response
    
    I visit the form responses page for the specific form and student
    And I fill in the form response
  Scenario: Viewing form responses for a specific form
    Given I visit the form responses page for a specific form
    Then I should see a list of responses for that form
    And I should not see responses from other forms

  Scenario: Viewing form responses for a specific student
    Given I visit the form responses page for a specific student
    Then I should see a list of responses for that student
    And I should not see responses from other students

  Scenario: Viewing all form responses
    Given I visit the form responses page for all forms
    Then I should see a list of all form responses
   