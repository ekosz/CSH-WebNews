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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110722021456) do

  create_table "newsgroups", :force => true do |t|
    t.string "name"
    t.string "status"
  end

  create_table "posts", :force => true do |t|
    t.string   "newsgroup"
    t.integer  "number"
    t.string   "subject"
    t.string   "author"
    t.datetime "date"
    t.string   "message_id"
    t.string   "references"
    t.string   "first_line"
    t.text     "headers"
    t.text     "body"
  end

  add_index "posts", ["message_id"], :name => "index_posts_on_message_id"
  add_index "posts", ["newsgroup", "number"], :name => "index_posts_on_newsgroup_and_number", :unique => true
  add_index "posts", ["references"], :name => "index_posts_on_references"

  create_table "unread_post_entries", :force => true do |t|
    t.integer "user_id"
    t.integer "newsgroup_id"
    t.integer "post_id"
    t.integer "personal_level"
  end

  add_index "unread_post_entries", ["user_id", "post_id"], :name => "index_unread_post_entries_on_user_id_and_post_id", :unique => true

  create_table "users", :force => true do |t|
    t.string   "username"
    t.string   "real_name"
    t.text     "preferences"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
