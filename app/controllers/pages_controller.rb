class PagesController < ApplicationController
  before_filter :sync_posts, :only => [:home, :check_new]
  before_filter :get_newsgroups, :only => :home

  def home
    @current_user.real_name = ENV['WEBAUTH_LDAP_CN']
    @current_user.save!
  end
  
  def new_user
  end
  
  def check_new
  end
  
  private
  
    def sync_posts
      if not File.exists?('tmp/syncing.txt') and
          (not File.exists?('tmp/lastsync.txt') or File.mtime('tmp/lastsync.txt') < 1.minute.ago)
        FileUtils.touch('tmp/syncing.txt')
        Newsgroup.sync_all!
        FileUtils.rm('tmp/syncing.txt')
        FileUtils.touch('tmp/lastsync.txt')
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
