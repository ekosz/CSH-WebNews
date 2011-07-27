class Post < ActiveRecord::Base
  set_primary_keys :newsgroup, :number
  belongs_to :newsgroup, :foreign_key => :newsgroup, :primary_key => :name
  
  def parent
    Post.where(:message_id => references, :newsgroup => newsgroup.name).first
  end
  
  def children
    Post.where(:references => message_id).order('date')
  end
  
  def authored_by?(user)
    author_name == user.real_name or author_email == user.email
  end
  
  def user_in_thread?(user)
    return true if authored_by?(user)
    children.each do |child|
      return true if child.user_in_thread?(user)
    end
    return false
  end
  
  def author_name
    author[/"?(.*?)"? <.*>/, 1] || author[/.* \((.*)\)/, 1] || author
  end
  
  def author_email
    author[/"?.*?"? <(.*)>/, 1] || author[/(.*) \(.*\)/, 1] || nil
  end
  
  def short_headers
    [
      headers[/From: .*/],
      headers[/Date: .*/],
      headers[/Subject: .*/],
      headers[/Message-ID: .*/]
    ].join("\n")
  end
end
