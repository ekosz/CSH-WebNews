class User < ActiveRecord::Base
  serialize :preferences, Hash
  has_many :unread_post_entries
  has_many :unread_posts, :through => :unread_post_entries, :source => :post
  
  def email
    username + '@csh.rit.edu'
  end
end
