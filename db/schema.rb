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

ActiveRecord::Schema[8.0].define(version: 2025_09_05_195003) do
  create_table "choices", force: :cascade do |t|
    t.integer "poll_id", null: false
    t.string "label", null: false
    t.integer "votes_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["poll_id"], name: "index_choices_on_poll_id"
  end

  create_table "polls", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "slug", null: false
    t.integer "status", default: 0, null: false
    t.datetime "ends_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_polls_on_slug", unique: true
  end

  create_table "votes", force: :cascade do |t|
    t.integer "poll_id", null: false
    t.integer "choice_id", null: false
    t.string "voter_hash"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["choice_id"], name: "index_votes_on_choice_id"
    t.index ["poll_id", "voter_hash"], name: "index_votes_on_poll_id_and_voter_hash", unique: true, where: "voter_hash IS NOT NULL"
    t.index ["poll_id"], name: "index_votes_on_poll_id"
  end

  add_foreign_key "choices", "polls"
  add_foreign_key "votes", "choices"
  add_foreign_key "votes", "polls"
end
