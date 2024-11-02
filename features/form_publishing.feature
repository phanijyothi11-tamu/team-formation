Feature: Form Publishing Management
  As a professor
  I want to manage the publishing status of my forms
  So that I can control when students can access and submit responses

  Background:
    Given I am logged in as a professor
    And I have created a form
    And I have added the following attributes to the form:
      | Name       | Field Type  | Options | Min Value | Max Value |
      | Question 1 | text_input  |         |          |           |
    And the deadline is set
    And students with IDs 1 and 2 have access to the form

  Scenario: Publishing a form
    When I navigate to my user profile page
    And I click on "View" for that form
    And I click "Publish Form"
    Then The form should be published
    And The students with IDs 1 and 2 can access the form

  Scenario: Closing a published form
    Given I have created a form that is published
    When I navigate to my user profile page
    And I click on "View" for that form
    And I click "Close Form"
    Then The form should be closed
    And The students with IDs 1 and 2 cannot access the form

  Scenario: Re-publishing a closed form
    Given I have a form that is closed
    When I navigate to my user profile page
    And I click on "View" for that form
    And I click "Publish Form"
    Then The form should be published
    And The students with IDs 1 and 2 can access the form