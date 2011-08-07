require 'net/nntp'

namespace :nntp do
  desc "Delete and re-import all groups and posts"
  task :reload => :environment do
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
  
  desc "Sync all newsgroups with the current state of news"
  task :resync => :environment do
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
          Post.import!(n, number, head, body)
          print '.'
        end
        puts
      end
    end
  end
end
