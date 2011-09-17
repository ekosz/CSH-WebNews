class PostsController < ApplicationController
  before_filter :get_newsgroup, :only => [:index, :search, :search_entry, :show, :new]
  before_filter :get_post, :only => [:show, :new, :destroy, :destroy_confirm]
  before_filter :get_newsgroups, :only => :search_entry
  before_filter :get_newsgroups_for_posting, :only => [:new, :create]
  before_filter :set_list_layout_and_offset, :only => [:index, :search]

  def index
    @not_found = true if params[:not_found]
    
    if params[:showing]
      limit = 11
      @showing = @newsgroup.posts.find_by_number(params[:showing])
      showing_thread = @showing.thread_parent
      @posts = @newsgroup.posts.
        where('parent_id = ? and date >= ?', '', showing_thread.date).
        order('date DESC')
      @posts += @newsgroup.posts.
        where('parent_id = ? and date < ?', '', showing_thread.date).
        order('date DESC').limit(limit)
    else
      limit = 16
      @posts = @newsgroup.posts.
        where('parent_id = ? and date < ?', '', @from).
        order('date DESC').limit(limit)
    end
    
    @more = @posts.length > 0 && !@posts[limit - 1].nil?
    @posts.delete_at(-1) if @posts.length == limit
  end
  
  def search
    limit = 16
    conditions, values, error_text = build_search_conditions
    
    conditions << 'date < ?'
    values << @from
    if not @newsgroup
      conditions << 'newsgroup not like ?'
      values << 'control%'
    end
    
    if params[:validate]
      if error_text
        form_error error_text
      else
        remove_params = %w[action controller source commit validate utf8 _]
        search_params = params.select{ |k,v| not remove_params.include?(k) }
        search_params.reject!{ |k,v| v.blank? }
        render :partial => 'search_redirect', :locals => { :search_params => search_params }
      end
      return
    elsif error_text
      # Should only happen if someone messes with URLs
      render :nothing => true and return
    end
    
    @search_mode = true
    @posts = Post.where(conditions.join(' and '), *values).order('date DESC').limit(limit)
    @more = @posts.length > 0 && !@posts[limit - 1].nil?
    @posts.delete_at(-1) if @posts.length == limit
    render 'index'
  end
  
  def search_entry
  end
  
  def show
    @search_mode = (params[:search_mode] ? true : false)
    if @post
      @post_was_unread = @post.mark_read_for_user(@current_user)
      get_next_unread_post if @post_was_unread
    else
      @not_found = true
    end
  end
  
  def new
    @new_post = Post.new(:newsgroup => @newsgroup)
    if @post
      @new_post.subject = 'Re: ' + @post.subject.sub(/^Re: ?/, '')
      @new_post.body = @post.quoted_body
    end
  end
  
  def create
    @sync_error_text = nil
  
    if params[:post][:subject].blank?
      form_error "You must enter a subject line for your post." and return
    end
    
    newsgroup = @newsgroups.where_posting_allowed.find_by_name(params[:post][:newsgroup])
    if newsgroup.nil?
      form_error "The newsgroup you are trying to post to either doesn't exist or doesn't allow posting." and return
    end
    
    reply_newsgroup = reply_post = nil
    if params[:post][:reply_newsgroup]
      reply_newsgroup = Newsgroup.find_by_name(params[:post][:reply_newsgroup])
      reply_post = Post.where(:newsgroup => params[:post][:reply_newsgroup],
        :number => params[:post][:reply_number]).first
      if reply_post.nil?
        form_error "The post you are trying to reply to doesn't exist; it may have been canceled. Try refreshing the newsgroup." and return
      end
    end
    
    post_string = Post.build_message(
      :user => @current_user,
      :newsgroup => newsgroup,
      :subject => params[:post][:subject],
      :body => params[:post][:body],
      :reply_post => reply_post
    )
    
    new_message_id = nil
    begin
      Net::NNTP.start(NEWS_SERVER) do |nntp|
        new_message_id = nntp.post(post_string)[1][/<.*?>/]
      end
    rescue
      form_error 'Error: ' + $!.message and return
    end
    
    begin
      Net::NNTP.start(NEWS_SERVER) do |nntp|
        Newsgroup.sync_group!(nntp, newsgroup.name, newsgroup.status)
      end
    rescue
      @sync_error = "Your post was accepted by the news server, but an error occurred while attempting to sync the newsgroup it was posted to. This may be a transient issue: Wait a couple minutes and manually refresh the newsgroup, and you should see your post.\n\nThe exact error was: #{$!.message}"
    end
    
    @new_post = Post.find_by_message_id(new_message_id)
    if not @new_post
      @sync_error = "Your post was accepted by the news server, but doesn't appear to actually exist; it may have been held for moderation or silently discarded (though neither of these should ever happen on CSH news). Wait a couple minutes and manually refresh the newsgroup to make sure this isn't a glitch in WebNews."
    end
  end
  
  def destroy
    if not @post.newsgroup.posting_allowed?
      form_error "The newsgroup containing the post you are trying to cancel is read-only. Posts in read-only newsgroups cannot be canceled." and return
    end
    
    if @post.nil?
      form_error "The post you are trying to cancel doesn't exist; it may have already been canceled. Try manually refreshing the newsgroup." and return
    end
    
    begin
      Net::NNTP.start(NEWS_SERVER) do |nntp|
        nntp.post(@post.build_cancel_message(@current_user, params[:reason]))
      end
    rescue
      form_error 'Error: ' + $!.message and return
    end
    
    begin
      Net::NNTP.start(NEWS_SERVER) do |nntp|
        Newsgroup.sync_group!(nntp, @post.newsgroup.name, @post.newsgroup.status)
      end
    rescue
      @sync_error = "Your cancel was accepted by the news server, but an error occurred while attempting to sync the newsgroup containing the canceled post. This may be a transient issue: Wait a couple minutes and manually refresh the newsgroup, and the post should be gone.\n\nThe exact error was: #{$!.message}"
    end
  end
  
  def destroy_confirm
  end
  
  private
    
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
    
    def get_newsgroups_for_posting
      @newsgroups = Newsgroup.where_posting_allowed
    end
    
    def set_list_layout_and_offset
      @full_layout = true
      @from = if params[:from]
        @full_layout = false
        DateTime.parse(params[:from])
      else
        DateTime.now + 1.second
      end
    end
    
    def build_search_conditions
      conditions = []
      values = []
      error_text = nil
      
      if @newsgroup
        conditions << 'newsgroup = ?'
        values << @newsgroup.name
      end
      
      if not params[:keywords].blank?
        begin
          phrases = Shellwords.split(params[:keywords])
          keyword_conditions = []
          keyword_values = []
          exclude_conditions = []
          exclude_values = []
          
          phrases.each do |phrase|
            if phrase[0] == '-'
              exclude_conditions << 'subject like ?'
              exclude_values << '%' + phrase[1..-1] + '%'
              if not params[:subject_only]
                exclude_conditions << 'body like ?'
                exclude_values << '%' + phrase[1..-1] + '%'
              end
            else
              keyword_conditions << 'subject like ?'
              keyword_values << '%' + phrase + '%'
              if not params[:subject_only]
                keyword_conditions << 'body like ?'
                keyword_values << '%' + phrase + '%'
              end
            end
          end
          
          conditions << '(' + 
            '(' + keyword_conditions.join(' or ') + ')' + (
              exclude_conditions.empty? ?
                '' : ' and not (' + exclude_conditions.join(' or ') + ')'
            ) + ')'
          values += keyword_values + exclude_values
        rescue
          error_text = "Keywords field has unbalanced quotes."
        end
      end
      
      if not params[:author].blank?
        conditions << 'author like ?'
        values << '%' + params[:author] + '%'
      end
      
      if not params[:date_from].blank?
        date_from = params[:date_from]
        date_from = 'January 1, ' + date_from if date_from[/^\d{4}$/]
        date_from = Chronic.parse(date_from)
        if not date_from
          error_text = "Unable to parse \"#{params[:date_from]}\"."
        else
          conditions << 'date > ?'
          values << date_from
        end
      end
      if not params[:date_to].blank?
        date_to = params[:date_to]
        date_to = 'January 1, ' + (date_to.to_i + 1).to_s if date_to[/^\d{4}$/]
        date_to = Chronic.parse(date_to)
        if not date_to
          error_text = "Unable to parse \"#{params[:date_to]}\"."
        else
          conditions << 'date < ?'
          values << date_to
        end
      end
      
      return conditions, values, error_text
    end
end
