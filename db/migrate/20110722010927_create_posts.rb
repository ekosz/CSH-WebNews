class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string :newsgroup
      t.integer :number
      t.string :subject
      t.string :author
      t.datetime :date
      t.string :message_id
      t.string :references
      t.string :first_line
      t.text :headers
      t.text :body
    end
    add_index :posts, [:newsgroup, :number]
    add_index :posts, :message_id
  end
end
