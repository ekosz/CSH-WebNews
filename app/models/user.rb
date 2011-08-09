class User < ActiveRecord::Base
  has_many :unread_post_entries
  has_many :unread_posts, :through => :unread_post_entries, :source => :post
  
  serialize :preferences, Hash
  attr_readonly :username, :real_name
  
  def email
    username + '@csh.rit.edu'
  end
  
  def time_zone
    preferences[:time_zone] || 'Eastern Time (US & Canada)'
  end
  
  def unread_in_test?
    (preferences[:unread_in_test] == '1') || false
  end
  
  def unread_in_control?
    (preferences[:unread_in_control] == '1') || false
  end
  
  def unread_in_lists?
    (preferences[:unread_in_lists] == '1') || false
  end
  
  def unread_in_group?(newsgroup)
    return false if
      (newsgroup.name == 'csh.test' and not unread_in_test?) or
      (newsgroup.name[/^control/] and not unread_in_control?) or
      (newsgroup.name[/^csh.lists/] and not unread_in_lists?)
    return true
  end
  
  def unread_count
    unread_post_entries.count
  end
  
  def unread_count_in_thread
    unread_post_entries.where(:personal_level => PERSONAL_CODES[:mine_in_thread]).count
  end
  
  def unread_count_in_reply
    unread_post_entries.where(:personal_level => PERSONAL_CODES[:mine_reply]).count
  end
end
