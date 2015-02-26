# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20150226130918) do

  create_table "group_meta_keys", force: :cascade do |t|
    t.binary   "group_key_crypted", null: false
    t.binary   "group_iv_crypted",  null: false
    t.integer  "user_id"
    t.integer  "group_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "group_meta_keys", ["group_id"], name: "index_group_meta_keys_on_group_id"
  add_index "group_meta_keys", ["user_id", "group_id"], name: "index_group_meta_keys_on_user_id_and_group_id"
  add_index "group_meta_keys", ["user_id"], name: "index_group_meta_keys_on_user_id"

  create_table "groups", force: :cascade do |t|
    t.string   "name",                    limit: 256,  null: false
    t.string   "public_key_pem",          limit: 4096, null: false
    t.binary   "private_key_pem_crypted",              null: false
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  add_index "groups", ["name"], name: "index_groups_on_name", unique: true

  create_table "users", force: :cascade do |t|
    t.string   "name",                    limit: 256,  null: false
    t.string   "email",                   limit: 256,  null: false
    t.string   "public_key_pem",          limit: 4096, null: false
    t.binary   "private_key_pem_crypted",              null: false
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true

end
