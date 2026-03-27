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

ActiveRecord::Schema[8.1].define(version: 2026_03_21_092000) do
  create_table "makeup_allocations", force: :cascade do |t|
    t.bigint "allocatable_id", null: false
    t.string "allocatable_type", null: false
    t.datetime "created_at", null: false
    t.integer "makeup_fast_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["allocatable_type", "allocatable_id"], name: "idx_on_allocatable_type_allocatable_id_acb678156f"
    t.index ["makeup_fast_id"], name: "index_makeup_allocations_on_makeup_fast_id", unique: true
    t.index ["user_id"], name: "index_makeup_allocations_on_user_id"
  end

  create_table "makeup_fasts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "fasted_on", null: false
    t.text "notes"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_makeup_fasts_on_user_id"
  end

  create_table "missed_fasts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "missed_on", null: false
    t.text "notes"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "missed_on"], name: "index_missed_fasts_on_user_id_and_missed_on", unique: true
    t.index ["user_id"], name: "index_missed_fasts_on_user_id"
  end

  create_table "ramadan_season_balances", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "gregorian_year"
    t.integer "hijri_year"
    t.text "notes"
    t.integer "owed_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_ramadan_season_balances_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "makeup_allocations", "makeup_fasts"
  add_foreign_key "makeup_allocations", "users"
  add_foreign_key "makeup_fasts", "users"
  add_foreign_key "missed_fasts", "users"
  add_foreign_key "ramadan_season_balances", "users"
  add_foreign_key "sessions", "users"
end
