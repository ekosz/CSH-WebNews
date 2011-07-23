class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :username
      t.string :real_name
      t.text :preferences

      t.timestamps
    end
  end
end
