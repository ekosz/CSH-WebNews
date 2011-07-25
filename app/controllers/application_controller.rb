class ApplicationController < ActionController::Base
  require 'net/nntp'
  protect_from_forgery
  before_filter :get_current_user
  
  private
  
    def get_current_user
      @current_user = User.find_by_username(ENV['WEBAUTH_USER'])
      @current_user.touch if not @current_user.nil?
    end
end
