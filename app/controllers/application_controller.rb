class ApplicationController < ActionController::Base
  require 'net/nntp'
  protect_from_forgery
  before_filter :set_request_for_dev
  before_filter :authenticate, :check_maintenance, :get_or_create_user
  
  private
  
    def authenticate
      if not request.env['WEBAUTH_USER']
        render :file => "#{Rails.root}/public/auth.html", :layout => false
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
      @current_user = User.find_by_username(request.env['WEBAUTH_USER'])
      if @current_user.nil?
        @current_user = User.create!(
          :username => request.env['WEBAUTH_USER'],
          :real_name => request.env['WEBAUTH_LDAP_CN'],
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

    def set_request_for_dev
      if Rails.env.development?
        request.env['WEBAUTH_USER'] = 'dev'
        request.env['WEBAUTH_LDAP_CN'] = 'Devlop Err'
      end
    end
end
