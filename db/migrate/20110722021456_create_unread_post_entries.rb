class CreateUnreadPostEntries < ActiveRecord::Migration
  def change
    create_table :unread_post_entries do |t|
      t.references :user
      t.references :post
      t.integer :personal_level
    end
    add_index :unread_post_entries, [:user_id, :post_id], :unique => true
  end
end
