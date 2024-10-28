Feature: Form Responses
    Given there is a published form
    Given there is a logged student
    Given associated Form response
    Scenario: Creating a new form response
    
    I visit the form responses page for the specific form and student
    And I fill in the form response 
    
