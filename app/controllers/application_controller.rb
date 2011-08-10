class ApplicationController < ActionController::Base
  require 'net/nntp'
  protect_from_forgery
  before_filter :authenticate, :check_maintenance, :get_or_create_user
  
  private
  
    def authenticate
      if not ENV['WEBAUTH_USER']
        render :file => "#{RAILS_ROOT}/public/auth.html"
      end
    end
    
    def check_maintenance
      if File.exists?('tmp/maintenance.txt')
        @no_script = true
        @explanation = File.read('tmp/maintenance.txt')
        respond_to do |wants|
          wants.html { render 'shared/maintenance' }
          wants.js { render 'shared/maintenance' }
        end
      end
    end
  
    def get_or_create_user
      @current_user = User.find_by_username(ENV['WEBAUTH_USER'])
      if @current_user.nil?
        @current_user = User.create!(
          :username => ENV['WEBAUTH_USER'],
          :real_name => ENV['WEBAUTH_LDAP_CN'],
          :preferences => {}
        )
        @new_user = true
      else
        @current_user.touch
      end
    end
    
    def get_next_unread_post
      @next_unread_post = @current_user.unread_posts.order('newsgroup, date').first
    end
end
