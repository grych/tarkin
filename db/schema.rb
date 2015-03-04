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

ActiveRecord::Schema.define(version: 20150304144806) do

  create_table "directories", force: :cascade do |t|
    t.string   "name",         limit: 256, null: false
    t.text     "description"
    t.integer  "directory_id"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "directories", ["directory_id"], name: "index_directories_on_directory_id"
  add_index "directories", ["name"], name: "index_directories_on_name"

  create_table "directories_groups", force: :cascade do |t|
    t.integer "directory_id"
    t.integer "group_id"
  end

  add_index "directories_groups", ["directory_id"], name: "index_directories_groups_on_directory_id"
  add_index "directories_groups", ["group_id"], name: "index_directories_groups_on_group_id"

  create_table "groups", force: :cascade do |t|
    t.string   "name",                    limit: 256,  null: false
    t.string   "public_key_pem",          limit: 4096, null: false
    t.binary   "private_key_pem_crypted",              null: false
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  add_index "groups", ["name"], name: "index_groups_on_name", unique: true

  create_table "items", force: :cascade do |t|
    t.string   "username",         limit: 256
    t.binary   "password_crypted"
    t.integer  "directory_id"
    t.text     "description"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "items", ["directory_id"], name: "index_items_on_directory_id"
  add_index "items", ["username"], name: "index_items_on_username"

  create_table "meta_keys", force: :cascade do |t|
    t.binary   "key_crypted", null: false
    t.binary   "iv_crypted",  null: false
    t.integer  "user_id"
    t.integer  "group_id"
    t.integer  "item_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "meta_keys", ["group_id", "item_id"], name: "index_meta_keys_on_group_id_and_item_id", unique: true
  add_index "meta_keys", ["group_id"], name: "index_meta_keys_on_group_id"
  add_index "meta_keys", ["item_id"], name: "index_meta_keys_on_item_id"
  add_index "meta_keys", ["user_id", "group_id"], name: "index_meta_keys_on_user_id_and_group_id", unique: true
  add_index "meta_keys", ["user_id"], name: "index_meta_keys_on_user_id"

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
