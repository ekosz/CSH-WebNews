class PagesController < ApplicationController
  before_filter :get_newsgroups, :only => :home

  def home
    @current_user.real_name = ENV['WEBAUTH_LDAP_CN']
    @current_user.save!
  end
  
  def new_user
  end
end
