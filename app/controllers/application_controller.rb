class ApplicationController < ActionController::Base
  require 'net/nntp'
  require 'shellwords'
  protect_from_forgery
  before_filter :authenticate, :check_maintenance, :get_or_create_user
  
  private
  
    def authenticate
      if not request.env['WEBAUTH_USER']
        set_no_cache
        render :file => "#{Rails.root}/public/auth.html", :layout => false
      end
    end
    
    def check_maintenance
      if File.exists?('tmp/maintenance.txt')
        set_no_cache
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
    
    def get_newsgroups
      @newsgroups = Newsgroup.unscoped.order('status DESC, name')
    end
    
    def get_next_unread_post
      @next_unread_post = @current_user.unread_posts.order('newsgroup, date').first
    end
    
    def form_error(error_text)
      render :partial => 'shared/form_error', :object => error_text
    end
    
    def set_no_cache
      response.headers['Cache-Control'] =
        'must-revalidate, private, no-cache, no-store, max-age=0'
      response.headers['Pragma'] = 'no-cache'
      response.headers['Expires'] = DateTime.now.rfc822
    end 
end
