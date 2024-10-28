# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2024_10_16_225834) do
  create_table "attributes", force: :cascade do |t|
    t.string "name"
    t.string "field_type"
    t.integer "min_value"
    t.integer "max_value"
    t.text "options"
    t.integer "form_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "weightage"
    t.index ["form_id"], name: "index_attributes_on_form_id"
  end

  create_table "form_responses", force: :cascade do |t|
    t.integer "form_id", null: false
    t.text "responses", default: "{}", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "student_id", null: false
    t.index ["form_id"], name: "index_form_responses_on_form_id"
    t.index ["student_id", "form_id"], name: "index_form_responses_on_student_id_and_form_id", unique: true
    t.index ["student_id"], name: "index_form_responses_on_student_id"
  end

  create_table "forms", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deadline"
    t.integer "user_id", null: false
    t.boolean "published"
  end

  create_table "students", force: :cascade do |t|
    t.string "uin"
    t.string "name"
    t.string "email"
    t.string "section"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uin"], name: "index_students_on_uin", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "uin"
    t.string "name"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "attributes", "forms"
  add_foreign_key "form_responses", "forms"
  add_foreign_key "form_responses", "students"
  add_foreign_key "forms", "users"
end
