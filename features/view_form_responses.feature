Feature: View Student Responses

  Scenario: Professor views list of student responses
    Given I log in as a professor
    And I have already published a form
    And students have submitted their responses
    When I click on "View Responses" to view responses for a form
    Then I should see a list of student responses

  Scenario: Professor views detailed student response
    Given I log in as a professor
    And I have already published a form
    And students have submitted their responses
    When I click on "View Responses" to view responses for a form
    And I select a response and click on "View Details"
    Then I should see the detailed response
