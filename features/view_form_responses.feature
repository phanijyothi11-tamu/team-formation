Feature: View Student Responses

  Background:
    Given I log in as a professor

  Scenario: Professor cannot view responses for an unpublished form
    Given I have created a form that is not published
    When I visit my user profile page
    Then I should not see "View Responses" for that form
    And I should see "Edit" button for that form

  Scenario: Professor can view responses for a published form
    Given I have created a form that is published
    When I visit my user profile page
    Then I should see "View Responses" for that form
    And I should not see "Edit" for that form

  Scenario: Professor views list of student responses
    Given I have already published a form
    And students have submitted their responses
    When I click on "View Responses" to view responses for a form
    Then I should see a list of student responses

  Scenario: Professor views detailed student response
    Given I have already published a form
    And students have submitted their responses
    When I click on "View Responses" to view responses for a form
    And I select a response and click on "View Details"
    Then I should see the detailed response
