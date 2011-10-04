class ApplicationController < ActionController::Base
  require 'net/nntp'
  require 'shellwords'
  protect_from_forgery
  before_filter :authenticate, :check_maintenance, :get_or_create_user
  
  private
  
    def authenticate
      if not request.env['WEBAUTH_USER']
        set_no_cache
        respond_to do |wants|
          wants.html { render :file => "#{Rails.root}/public/auth.html", :layout => false }
          wants.js { render 'shared/needs_auth' }
        end
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
    
    def get_newsgroup
      if params[:newsgroup]
        @newsgroup = Newsgroup.find_by_name(params[:newsgroup])
      end
    end
    
    def get_post
      if params[:newsgroup] and params[:number]
        @post = Post.where(:number => params[:number], :newsgroup => params[:newsgroup]).first
      end
    end
    
    def get_next_unread_post
      if @post
        order = "CASE newsgroup WHEN #{Post.sanitize(@post.newsgroup.name)} THEN 1 ELSE 2 END,
        CASE thread_id WHEN #{Post.sanitize(@post.thread_id)} THEN 1 ELSE 2 END, newsgroup, date"
      elsif @newsgroup
        order = "CASE newsgroup WHEN #{Post.sanitize(@newsgroup.name)} THEN 1 ELSE 2 END, newsgroup, date"
      else
        order = 'newsgroup, date'
      end
      @next_unread_post = @current_user.unread_posts.order(order).first
    end
    
    def form_error(error_text)
      render :partial => 'shared/form_error', :object => error_text
    end
    
    def set_no_cache
      response.headers['Cache-Control'] =
        'no-store, no-cache, private, must-revalidate, max-age=0'
      response.headers['Pragma'] = 'no-cache'
      response.headers['Expires'] = '0'
      response.headers['Vary'] = '*'
    end 
end
