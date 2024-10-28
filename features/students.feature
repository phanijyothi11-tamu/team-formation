
Feature: View Student Information

  Scenario: Viewing student details
    Given there is a student with ID 1
    When I visit the student details page
    Then I should see the student's information