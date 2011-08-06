class Newsgroup < ActiveRecord::Base
  has_many :posts, :foreign_key => :newsgroup, :primary_key => :name, :dependent => :destroy
  
  default_scope :order => 'name'
end
