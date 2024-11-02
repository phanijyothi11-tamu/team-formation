Feature: Form Deadline Expiration
  As a professor
  I want forms to automatically close after their deadline
  So that students cannot submit responses after the due date

  Background:
    Given I am logged in as a professor
    And I have created a form with attributes

  Scenario: Form automatically closes after deadline
    When I set the deadline to 5 seconds from now
    And I publish the form
    And I wait for 6 seconds
    Then the form should be automatically closed

  Scenario: Students cannot view expired forms
    Given there is a student with ID 1
    And I set the deadline to 5 seconds from now
    And I publish the form
    When I wait for 6 seconds
    And The student with ID 1 cannot access the form

  Scenario: Professor views expired form status
    When I set the deadline to 5 seconds from now
    And I publish the form
    And I wait for 6 seconds
    And I navigate to my user profile page
    Then I should see "Draft" status for that form