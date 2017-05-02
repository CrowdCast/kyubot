# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170501080581) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "requests", force: :cascade do |t|
    t.string   "description"
    t.date     "days",        default: [], null: false, array: true
    t.integer  "status",      default: 0,  null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "user_id"
    t.index ["user_id"], name: "index_requests_on_user_id", using: :btree
  end

  create_table "teams", force: :cascade do |t|
    t.string   "slack_id",    null: false
    t.string   "slack_token", null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "slack_name",                                          null: false
    t.text     "description"
    t.decimal  "allowance",   precision: 4, scale: 2, default: "0.0", null: false
    t.decimal  "days_taken",  precision: 4, scale: 2, default: "0.0", null: false
    t.boolean  "is_approver",                         default: false, null: false
    t.string   "slack_id",                                            null: false
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.integer  "team_id"
    t.index ["team_id"], name: "index_users_on_team_id", using: :btree
  end

  add_foreign_key "requests", "users"
  add_foreign_key "users", "teams"
end
