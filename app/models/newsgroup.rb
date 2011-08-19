class Newsgroup < ActiveRecord::Base
  has_many :unread_post_entries, :dependent => :destroy
  has_many :posts, :foreign_key => :newsgroup, :primary_key => :name, :dependent => :destroy
  
  default_scope :order => 'name'
  scope :where_posting_allowed, where(:status => 'y')
  
  def posting_allowed?
    status == 'y'
  end
  
  def unread_for_user(user)
    hclass = ''
    count = unread_post_entries.where(:user_id => user.id).count
    max_level = unread_post_entries.where(:user_id => user.id).maximum(:personal_level)
    if max_level
      hclass = 'unread ' + PERSONAL_CLASSES[max_level]
    end
    return { :count => count, :hclass => hclass }
  end
  
  def self.sync_group!(nntp, name, status, standalone = true, full_reload = false)
    if standalone
      sleep 0.1 until not File.exists?('tmp/syncing.txt')
      FileUtils.touch('tmp/syncing.txt')
    end
    
    if Newsgroup.where(:name => name).exists?
      newsgroup = Newsgroup.where(:name => name).first
      newsgroup.update_attributes(:status => status)
    else
      newsgroup = Newsgroup.create!(:name => name, :status => status)
    end
    
    puts nntp.group(newsgroup.name)[1]
    my_posts = Post.where(:newsgroup => newsgroup.name).select(:number).map(&:number)
    news_posts = nntp.listgroup(newsgroup.name)[1].map(&:to_i)
    to_delete = my_posts - news_posts
    to_import = news_posts - my_posts
    
    puts "Deleting #{to_delete.size} posts."
    to_delete.each do |number|
      Post.where(:newsgroup => newsgroup.name, :number => number).first.destroy
    end
    
    puts "Importing #{to_import.size} posts."
    to_import.each do |number|
      head = nntp.head(number)[1].join("\n")
      body = nntp.body(number)[1].join("\n")
      post = Post.import!(newsgroup, number, head, body)
      if not full_reload
        User.find_each do |user|
          if not post.authored_by?(user) and user.unread_in_group?(newsgroup)
            UnreadPostEntry.create!(:user => user, :newsgroup => newsgroup, :post => post,
              :personal_level => PERSONAL_CODES[post.personal_class_for_user(user)])
          end
        end
      end
      print '.'
    end
    puts
    
    FileUtils.rm('tmp/syncing.txt') if standalone
  end
  
  def self.sync_all!(full_reload = false)
    puts "Waiting for any active sync to complete...\n\n"
    sleep 0.1 until not File.exists?('tmp/syncing.txt')
    FileUtils.touch('tmp/syncing.txt')
    Net::NNTP.start(NEWS_SERVER) do |nntp|
      my_groups = Newsgroup.select(:name).collect(&:name)
      news_groups = nntp.list[1].collect{ |line| line.split[0] }
      (my_groups - news_groups).each{ |name| Newsgroup.find_by_name(name).destroy }
      
      nntp.list[1].each do |line|
        s = line.split
        sync_group!(nntp, s[0], s[3], false, full_reload)
      end
    end
    FileUtils.touch('tmp/lastsync.txt')
    FileUtils.rm('tmp/syncing.txt')
  end
  
  def self.reload_all!
    sleep 0.1 until not File.exists?('tmp/syncing.txt')
    FileUtils.touch('tmp/syncing.txt')
    UnreadPostEntry.delete_all
    Post.delete_all
    Newsgroup.delete_all
    FileUtils.rm('tmp/syncing.txt')
    sync_all!(true)
  end
end
