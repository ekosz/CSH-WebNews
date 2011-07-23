class Newsgroup < ActiveRecord::Base
  has_many :posts, :foreign_key => :newsgroup, :primary_key => :name
end
