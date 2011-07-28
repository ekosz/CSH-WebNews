class ApplicationController < ActionController::Base
  require 'net/nntp'
  protect_from_forgery
  before_filter :authenticate, :get_user
  
  private
  
    def authenticate
      if not ENV['WEBAUTH_USER']
        render :file => "#{RAILS_ROOT}/public/auth.html"
      end
    end
  
    def get_user
      @current_user = User.find_by_username(ENV['WEBAUTH_USER'])
      @current_user.touch if not @current_user.nil?
    end
end
