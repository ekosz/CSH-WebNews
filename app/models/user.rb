class User < ActiveRecord::Base
  has_many :unread_post_entries
  has_many :unread_posts, :through => :unread_post_entries, :source => :post
  
  serialize :preferences, Hash
  attr_accessible :preferences
  
  def email
    username + '@csh.rit.edu'
  end
  
  def time_zone
    preferences[:time_zone] || 'Eastern Time (US & Canada)'
  end
end
