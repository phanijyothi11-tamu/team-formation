Feature: Populate teams based on gender

  Scenario: Populate teams with an even number of female students
    Given a form with a gender attribute exists
    And 4 female students, 4 male students, 2 other students, and 2 prefer-not-to-say students have submitted responses
    When teams are populated based on gender
    Then each team should have 2 female students if possible

  Scenario: Populate teams with an odd number of female students
    Given a form with a gender attribute exists
    And 5 female students, 3 male students, 2 other students, and 2 prefer-not-to-say students have submitted responses
    When teams are populated based on gender
    Then one team should have 3 female students

  Scenario: Ensure that each team has at least one "other" student if possible
    Given a form with a gender attribute exists
    And 4 female students, 4 male students, 3 other students, and 1 prefer-not-to-say student have submitted responses
    When teams are populated based on gender
    Then each team with 2 or 3 female students should have one "other" student if available
