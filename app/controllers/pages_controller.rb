class PagesController < ApplicationController
  before_filter :sync_posts, :only => [:home, :check_new]
  before_filter :get_newsgroups, :only => [:home, :check_new]

  def home
    respond_to do |wants|
      wants.html {
        @current_user.real_name = ENV['WEBAUTH_LDAP_CN']
        @current_user.save!
      }
      wants.js {
        @recent_posts = Post.
          where('newsgroup not like ? and author like ?', 'control%', "%#{@current_user.email}%").
          order('date DESC').limit(10)
      }
    end
  end
  
  def new_user
  end
  
  def check_new
  end
  
  private
  
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
    
    def get_newsgroups
      @newsgroups = if @current_user.preferences[:show_cancel] == '1'
        Newsgroup.all
      else
        Newsgroup.where(:status => 'y')
      end
    end
end
