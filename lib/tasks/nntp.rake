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
end
