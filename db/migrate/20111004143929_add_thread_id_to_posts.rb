class AddThreadIdToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :thread_id, :string, :after => :parent_id
    add_index :posts, :thread_id
  end
end
