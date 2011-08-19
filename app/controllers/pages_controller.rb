class PagesController < ApplicationController
  before_filter :get_newsgroups, :only => [:home, :check_new]

  def home
    respond_to do |wants|
      
      wants.html do
        @current_user.real_name = request.env['WEBAUTH_LDAP_CN']
        @current_user.save!
        sync_posts
        get_next_unread_post
      end
      
      wants.js do
        get_activity_feed
      end
      
    end
  end
  
  def about
  end
  
  def new_user
  end
  
  def check_new
    sync_posts
    get_next_unread_post
    if params[:location] == '#!/home'
      @dashboard_active = true
      get_activity_feed
    end
  end
  
  def mark_read
    if params[:newsgroup]
      @current_user.unread_post_entries.
        where(:newsgroup_id => Newsgroup.find_by_name(params[:newsgroup]).id).destroy_all
    else
      @current_user.unread_post_entries.destroy_all
    end
    render :nothing => true
  end
  
  private
    
    def get_newsgroups
      @newsgroups = Newsgroup.unscoped.order('status DESC, name')
    end
    
    def get_activity_feed
      recent_posts = Post.where('date > ?', 1.week.ago).order('date DESC')
      recent_posts.reject!{ |post| post.newsgroup.name[ACTIVITY_FEED_EXCLUDE] }
      
      @active_threads = {}
      recent_posts.each do |post|
        thread = post.thread_parent
        if @active_threads[thread].nil? or @active_threads[thread] < post.date
          @active_threads[thread] = post.date
        end
      end
    end
    
    def sync_posts
      if not File.exists?('tmp/syncing.txt') and
          (not File.exists?('tmp/lastsync.txt') or File.mtime('tmp/lastsync.txt') < 1.minute.ago)
        Newsgroup.sync_all!
      end
    end
end
