class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string :newsgroup
      t.integer :number
      t.string :subject
      t.string :author
      t.datetime :date
      t.string :message_id
      t.string :parent_id
      t.string :first_line
      t.text :headers
      t.text :body
    end
    add_index :posts, [:newsgroup, :number], :unique => true
    add_index :posts, :message_id
    add_index :posts, :parent_id
  end
end
