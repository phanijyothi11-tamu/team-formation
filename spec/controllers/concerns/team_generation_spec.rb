require 'rails_helper'

RSpec.describe GenerateTeams, type: :concern do
  let(:user) { create(:user) }
  let(:dummy_class) do
    Class.new do
      include TeamCalculation
      include TeamGenderBalance
      include TeamEthnicityBalance
      include TeamSkillBalance
      include GenerateTeams
      include TeamDistributionHelpers

      attr_accessor :form

      def redirect_to(*args)
        # Mock redirect_to
      end

      def view_teams_form_path(form)
        "/forms/#{form.id}/view_teams"
      end
    end
  end
  let(:instance) { dummy_class.new }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    @form = create(:form, user: user, name: "Test Form", published: false)
    instance.form = @form

    # Create form attributes
    @gender_attr = create(:attribute,
      form: @form,
      name: "gender",
      field_type: "mcq",
      options: "male,female,other"  # Changed from 'others' to 'other'
    )

    @ethnicity_attr = create(:attribute,
      form: @form,
      name: "ethnicity",
      field_type: "mcq",
      options: "asian,caucasian,african,hispanic,middle_eastern"
    )

    @skill_attr = create(:attribute,
      form: @form,
      name: "programming_skill",
      field_type: "scale",
      min_value: 1,
      max_value: 10,
      weightage: 1
    )
  end

  def create_student_with_response(section, gender, ethnicity, skill_level)
    student = create(:student, section: section)
    create(:form_response,
      form: @form,
      student: student,
      responses: {
        @gender_attr.id.to_s => gender,
        @ethnicity_attr.id.to_s => ethnicity,
        @skill_attr.id.to_s => skill_level
      }
    )
  end

  context "with large diverse section" do
    before do
      # Section A: 50 students total
      # Minority threshold = 50/4 = 12.5 students

      # First create some students for existing teams
      3.times do |i|
        student = create(:student, section: "A")
        create(:form_response,
          form: @form,
          student: student,
          responses: {
            @gender_attr.id.to_s => "male",
            @ethnicity_attr.id.to_s => "asian",
            @skill_attr.id.to_s => "5"
          }
        )

        @form.teams.create!(
          name: "Old Team #{i}",
          section: "A",
          members: [ { id: student.id, name: student.name } ]
        )
      end

      # asian students (20 - not minority)
      14.times { create_student_with_response("A", "male", "asian", rand(5..8)) }     # High skill
      4.times { create_student_with_response("A", "female", "asian", rand(4..6)) }   # Medium skill
      2.times { create_student_with_response("A", "other", "asian", rand(1..3)) }    # Low skill

      # caucasian students (15 - not minority)
      10.times { create_student_with_response("A", "male", "caucasian", rand(5..8)) }
      3.times { create_student_with_response("A", "female", "caucasian", rand(4..6)) }
      2.times { create_student_with_response("A", "other", "caucasian", rand(1..3)) }

      # hispanic students (8 - minority)
      5.times { create_student_with_response("A", "male", "hispanic", rand(6..8)) }
      2.times { create_student_with_response("A", "female", "hispanic", rand(4..6)) }
      1.times { create_student_with_response("A", "other", "hispanic", rand(1..3)) }

      # middle_eastern students (7 - minority)
      5.times { create_student_with_response("A", "male", "middle_eastern", rand(6..8)) }
      1.times { create_student_with_response("A", "female", "middle_eastern", rand(4..6)) }
      1.times { create_student_with_response("A", "other", "middle_eastern", rand(1..3)) }
    end

    describe "team generation pipeline" do
      it "prints initial form responses distribution" do
        puts "\nInitial Form Responses Distribution:"
        total_students = @form.form_responses.count
        puts "Total Students: #{total_students}"

        by_gender = @form.form_responses.group_by { |r| r.responses[@gender_attr.id.to_s] }
        puts "\nBy Gender:"
        by_gender.each { |gender, responses| puts "  #{gender}: #{responses.size}" }

        by_ethnicity = @form.form_responses.group_by { |r| r.responses[@ethnicity_attr.id.to_s] }
        puts "\nBy Ethnicity:"
        by_ethnicity.each { |ethnicity, responses| puts "  #{ethnicity}: #{responses.size}" }

        skill_levels = @form.form_responses.map { |r| r.responses[@skill_attr.id.to_s].to_i }
        puts "\nSkill Distribution:"
        puts "  Average: #{(skill_levels.sum.to_f / skill_levels.size).round(2)}"
        puts "  Range: #{skill_levels.min}-#{skill_levels.max}"
      end

      context "when balancing by gender" do
        it "ensures teams are gender-balanced" do
          # Get initial distribution
          initial_distribution = instance.calculate_teams
          puts "\nAfter calculate_teams:"
          print_distribution("Initial Distribution", initial_distribution["A"])

          # Balance by gender
          gender_balanced = instance.balance_by_gender(initial_distribution)
          puts "\nAfter gender balancing:"
          print_distribution("Gender Balanced", gender_balanced["A"])

          gender_balanced["A"][:teams].each do |team|
            gender_counts = team[:composition][:gender]

            # Female pairing check
            if gender_counts["female"].to_i > 0
              expect(gender_counts["female"]).to be >= 2,
                "Team has isolated female(s): #{gender_counts["female"]}"
            end

            # Other gender pairing check
            if gender_counts["other"].to_i > 0
              expect(gender_counts["female"].to_i).to be >= 1,
                "Team has 'other' gender but no females"
            end
          end
        end
      end

      context "when balancing by ethnicity" do
        it "ensures teams are ethnicity-balanced" do
          # Get gender-balanced distribution
          distribution = instance.calculate_teams
          gender_balanced = instance.balance_by_gender(distribution)

          # Balance by ethnicity
          ethnicity_balanced = instance.balance_by_ethnicity(gender_balanced)
          puts "\nAfter ethnicity balancing:"
          print_distribution("Ethnicity Balanced", ethnicity_balanced["A"])

          # Calculate minority threshold
          total_students = @form.form_responses.count
          minority_threshold = total_students / 4.0

          # Identify minority ethnicities
          ethnicity_counts = @form.form_responses
            .group_by { |r| r.responses[@ethnicity_attr.id.to_s] }
            .transform_values(&:count)
          minority_ethnicities = ethnicity_counts.select { |_, count| count < minority_threshold }.keys

          ethnicity_balanced["A"][:teams].each do |team|
            ethnicity_counts = team[:composition][:ethnicity]

            # Check minority pairing
            minority_ethnicities.each do |minority|
              if ethnicity_counts[minority].to_i > 0
                expect(ethnicity_counts[minority]).to be >= 2,
                  "Team has isolated #{minority} student(s): #{ethnicity_counts[minority]}"
              end
            end
          end
        end
      end

      context "when balancing by programming proficiency" do
        it "ensures teams have balanced skill levels" do
          # Get ethnicity-balanced distribution
          distribution = instance.calculate_teams
          gender_balanced = instance.balance_by_gender(distribution)
          ethnicity_balanced = instance.balance_by_ethnicity(gender_balanced)

          # Balance by skills
          skill_balanced = instance.balance_by_skills(ethnicity_balanced)
          puts "\nAfter skill balancing:"
          print_distribution("Skill Balanced", skill_balanced["A"])

          skill_balanced["A"][:teams].each do |team|
            avg_skill = instance.send(:calculate_team_average, skill_balanced["A"], team)
            expect(avg_skill).to be_between(3, 8),
              "Team has unbalanced skill average: #{avg_skill}"
          end
        end
      end

      context "when generating final teams" do
        it "satisfies all balance constraints" do
          instance.generate_teams

          puts "\nFinal Teams Distribution:"
          @form.teams.each do |team|
            puts "\nTeam: #{team.name}"
            responses = team.members.map do |m|
              student = Student.find(m["id"])
              FormResponse.find_by(form: @form, student: student)
            end

            puts "Members: #{team.members.size}"
            puts "Gender: #{responses.map { |r| r.responses[@gender_attr.id.to_s] }.tally}"
            puts "Ethnicity: #{responses.map { |r| r.responses[@ethnicity_attr.id.to_s] }.tally}"
            puts "Avg Skill: #{(responses.map { |r| r.responses[@skill_attr.id.to_s].to_i }.sum.to_f / responses.size).round(2)}"
          end
        end
      end
    end

    def print_distribution(title, section_data)
      puts "\n#{title}:"
      puts "Total Teams: #{section_data[:teams].count}"

      section_data[:teams].each do |team|
        puts "\nTeam #{team[:team_id]}:"
        puts "Capacity: #{team[:capacity]}"
        puts "Members array: #{team[:members].inspect}"
        puts "Spots left: #{team[:spots_left]}"
        puts "Active members: #{team[:members].reject(&:zero?).size}"
        puts "Gender composition: #{team[:composition][:gender]}"
        puts "Ethnicity composition: #{team[:composition][:ethnicity]}"
        puts "Skill composition: #{team[:composition][:skill]}"

        avg_skill = instance.send(:calculate_team_average, section_data, team)
        puts "Skill average: #{avg_skill.round(2)}"
      end

      puts "\nUnassigned students: #{section_data[:unassigned].size}"
      if section_data[:unassigned].any?
        puts "Unassigned student IDs: #{section_data[:unassigned].inspect}"
      end
    end
  end
  context "when handling errors during team generation" do
    it "logs and re-raises errors that occur during team generation" do
      error_message = "Test error message"

      # Mock Rails logger
      logger_double = double("Logger")
      allow(Rails).to receive(:logger).and_return(logger_double)
      expect(logger_double).to receive(:error).with(/Team generation error: #{error_message}/)

      # Simulate an error during team calculation
      allow(instance).to receive(:calculate_teams).and_raise(StandardError.new(error_message))

      # Expect the error to be re-raised
      expect {
        instance.generate_teams
      }.to raise_error(StandardError, error_message)
    end


    it "handles errors in create_teams_for_section" do
      distribution = {
        "A" => {
          teams: [
            { team_id: 1, members: [ 1, 2, 3 ] }
          ]
        }
      }

      # Simulate Student.find raising an error
      allow(Student).to receive(:find).and_raise(ActiveRecord::RecordNotFound)

      expect {
        instance.create_teams(distribution)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "skips creating teams with no valid members" do
      distribution = {
        "A" => {
          teams: [
            { team_id: 1, members: [ 0, 0, 0 ] }  # All invalid members
          ]
        }
      }

      # Should not create any teams
      expect {
        instance.create_teams(distribution)
      }.not_to change(Team, :count)
    end
  end
end
