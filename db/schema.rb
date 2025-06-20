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

ActiveRecord::Schema[8.0].define(version: 2025_06_21_162303) do
  create_table "alliances", force: :cascade do |t|
    t.string "name", null: false
    t.string "tag", null: false
    t.text "description", null: false
    t.string "server", null: false
    t.integer "admin_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_alliances_on_admin_id"
    t.index ["tag"], name: "index_alliances_on_tag", unique: true
  end

  create_table "players", force: :cascade do |t|
    t.string "username", null: false
    t.string "rank", null: false
    t.integer "level", null: false
    t.text "notes"
    t.boolean "active", default: true, null: false
    t.integer "alliance_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["alliance_id"], name: "index_players_on_alliance_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username", null: false
    t.string "display_name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 3, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "alliances", "users", column: "admin_id"
  add_foreign_key "players", "alliances"
end
