class AddFirstLineToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :first_line, :string
  end
end
