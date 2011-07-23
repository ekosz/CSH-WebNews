class Post < ActiveRecord::Base
  set_primary_keys :newsgroup, :number
  belongs_to :newsgroup, :foreign_key => :newsgroup, :primary_key => :name

  def to_param
    "#{newsgroup}/#{number}"
  end
end
