Feature: Duplicate Form

  Scenario: Successfully duplicate a form
    Given I am logged in as the professor
    And I have created a form with attributes
    When I visit the edit page for form
    Then I should see a link to duplicate the form
    When I click the "Duplicate Form"
    Then I should be redirected to the edit page for the duplicated form without redirecting to new tab
    And the new form should have the name "Copy of Test Form"