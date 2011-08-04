class PagesController < ApplicationController
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
    
    def get_newsgroups
      @newsgroups = if @current_user.preferences[:show_cancel] == '1'
        Newsgroup.all
      else
        Newsgroup.where(:status => 'y')
      end
    end
end
