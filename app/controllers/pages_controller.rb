class PagesController < ApplicationController
  before_filter :sync_posts, :only => [:home, :check_new]
  before_filter :get_newsgroups, :only => [:home, :check_new]

  def home
    respond_to do |wants|
      
      wants.html do
        @current_user.real_name = ENV['WEBAUTH_LDAP_CN']
        @current_user.save!
      end
      
      wants.js do
        recent_posts = Post.where('date > ?', 1.week.ago).order('date DESC')
        recent_posts.reject!{ |post| post.newsgroup.name[ACTIVITY_FEED_EXCLUDE] }
        
        # Careful, using recent_posts.where(...) would operate on the
        # original result set, not the modified one created by reject!
        @recent_threads = recent_posts.reject{ |post| post.references != '' }
        recent_replies = recent_posts - @recent_threads
        
        @active_threads = {}
        recent_replies.each do |post|
          thread = post.thread_parent
          if @active_threads[thread].nil? or @active_threads[thread] < post.date
            @active_threads[thread] = post.date
            @recent_threads -= [thread]
          end
        end
      end
      
    end
  end
  
  def new_user
  end
  
  def check_new
  end
  
  private
    
    def get_newsgroups
      @newsgroups = Newsgroup.all
    end
    
    def sync_posts
      if not (action_name == 'home' and request.xhr?)
        if not File.exists?('tmp/syncing.txt') and
            (not File.exists?('tmp/lastsync.txt') or File.mtime('tmp/lastsync.txt') < 1.minute.ago)
          FileUtils.touch('tmp/syncing.txt')
          Newsgroup.sync_all!
          FileUtils.touch('tmp/lastsync.txt')
          FileUtils.rm('tmp/syncing.txt')
        end
      end
    end
end
