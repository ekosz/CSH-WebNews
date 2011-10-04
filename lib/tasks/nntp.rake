require 'net/nntp'

namespace :nntp do
  desc "Delete and re-import all groups and posts"
  task :reload => :environment do
    Newsgroup.reload_all!
  end
  
  desc "Sync all newsgroups with the current state of news"
  task :sync => :environment do
    Newsgroup.sync_all!
  end
  
  task :threads => :environment do
    count = 0
    Post.find_each do |post|
      if post.thread_id.nil?
        post.thread_id = post.thread_parent_old.message_id
        post.save!
      end
      count += 1
      puts count if count % 100 == 0
    end
  end
end
