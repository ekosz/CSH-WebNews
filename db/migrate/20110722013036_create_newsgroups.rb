class CreateNewsgroups < ActiveRecord::Migration
  def change
    create_table :newsgroups do |t|
      t.string :name
      t.string :status
    end
  end
end
