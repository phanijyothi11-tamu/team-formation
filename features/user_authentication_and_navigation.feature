Feature: User Authentication and Navigation

  Scenario: Visitor sees welcome page
    Given I am not logged in
    When I visit the welcome page
    Then I should see "Welcome To Team Formation Aggies !"
    And I should see a "Login with Google" button

  Scenario: User logs in successfully
    Given I am on the welcome page
    When I clicks "Login with Google"
    And I authorize the application on Google
    Then I should be redirected to my user page

  Scenario: User logs in with unregistered email
    Given I am on the welcome page
    When I clicks "Login with Google"
    And I authorize the application with an unregistered email
    Then I should be redirected to the welcome page 

  Scenario: Logged in user visits welcome page
    Given I am logged in
    When I visit the welcome page
    Then I should be redirected to my user page
    And I should see "Howdy"

  Scenario: User views their profile
    Given I am logged in
    When I visit my user page
    Then I should see my email address
    And I should see my name
    And I should see a "Logout" link

  Scenario: User logs out
    Given I am logged in
    When I clicks "Logout"
    Then I should be redirected to the welcome page
    And I should see "You are logged out."
  Scenario: Logged in student visits welcome page
    Given I am logged in as a student
    When I visit the welcome page
    Then I should be redirected to my student page
    And I should see "Welcome back, Student!"
  Scenario: Student logs in successfully with Google
    Given I am on the welcome page
    When I click "Login with Google"
    And I authorize the application on Google as a student
    Then I should be redirected to my student page
    And I should see "Logged in as Student"
  Scenario: User logs in successfully with Google
    Given I am on the welcome page
    When I click "Login with Google"
    And I authorize the application on Google as a user
    Then I should be redirected to my user page
    And I should see a Logout button