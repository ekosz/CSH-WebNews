class AddPersonalLevelToUnreadPostEntries < ActiveRecord::Migration
  def change
    add_column :unread_post_entries, :personal_level, :integer
  end
end
