class Newsgroup < ActiveRecord::Base
  has_many :unread_post_entries, :dependent => :destroy
  has_many :posts, :foreign_key => :newsgroup, :primary_key => :name, :dependent => :destroy
  
  default_scope :order => 'name'
  
  def unread_for_user(user)
    hclass = ''
    count = unread_post_entries.where(:user_id => user.id).count
    max_level = unread_post_entries.where(:user_id => user.id).maximum(:personal_level)
    if max_level
      hclass = 'unread ' + PERSONAL_CLASSES[max_level]
    end
    return { :count => count, :hclass => hclass }
  end
  
  def self.reload_all!
    UnreadPostEntry.delete_all
    Post.delete_all
    Newsgroup.delete_all
    
    Net::NNTP.start('news.csh.rit.edu') do |nntp|
      nntp.list[1].each do |line|
        s = line.split
        n = Newsgroup.create!(:name => s[0], :status => s[3])
        
        puts nntp.group(n.name)[1]
        nntp.listgroup(n.name)[1].each do |number|
          head = nntp.head(number)[1].join("\n")
          body = nntp.body(number)[1].join("\n")
          Post.import!(n, number.to_i, head, body)
          print '.'
        end
        puts
      end
    end
  end
  
  def self.sync_all!
    Net::NNTP.start('news.csh.rit.edu') do |nntp|
      my_groups = Newsgroup.select(:name).collect(&:name)
      news_groups = nntp.list[1].collect{ |line| line.split[0] }
      (my_groups - news_groups).each{ |name| Newsgroup.find_by_name(name).destroy }
      
      nntp.list[1].each do |line|
        s = line.split
        if Newsgroup.where(:name => s[0]).exists?
          n = Newsgroup.where(:name => s[0]).first
        else
          n = Newsgroup.create!(:name => s[0], :status => s[3])
        end
        
        puts nntp.group(n.name)[1]
        my_posts = Post.where(:newsgroup => n.name).select(:number).map(&:number)
        news_posts = nntp.listgroup(n.name)[1].map(&:to_i)
        to_delete = my_posts - news_posts
        to_import = news_posts - my_posts
        
        puts "Deleting #{to_delete.size} posts."
        to_delete.each do |number|
          Post.where(:newsgroup => n.name, :number => number).first.destroy
        end
        
        puts "Importing #{to_import.size} posts."
        to_import.each do |number|
          head = nntp.head(number)[1].join("\n")
          body = nntp.body(number)[1].join("\n")
          post = Post.import!(n, number, head, body)
          User.find_each do |user|
            if not post.authored_by?(user)
              UnreadPostEntry.create!(:user => user, :newsgroup => n, :post => post,
                :personal_level => PERSONAL_CODES[post.personal_class_for_user(user)])
            end
          end
          print '.'
        end
        puts
      end
    end
  end
end
