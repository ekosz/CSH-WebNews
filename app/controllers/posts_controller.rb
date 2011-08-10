class PostsController < ApplicationController
  before_filter :get_newsgroup, :only => [:index, :show, :new]
  before_filter :get_post, :only => [:show, :new]
  before_filter :get_newsgroups_for_posting, :only => [:new, :create]

  def index
    @full_layout = true
    @from = if params[:from]
      @full_layout = false
      params[:from].to_i
    else
      @newsgroup.posts.maximum(:number) + 1
    end
    
    if params[:showing]
      @showing = @newsgroup.posts.find_by_number(params[:showing])
      @posts = @newsgroup.posts.
        where('"references" = ? and number >= ?', '', @showing.number).
        order('number DESC')
      @posts += @newsgroup.posts.
        where('"references" = ? and number < ?', '', @showing.number).
        order('number DESC').limit(10)
    else
      @posts = @newsgroup.posts.
        where('"references" = ? and number < ?', '', @from).
        order('number DESC').limit(10)
    end
    
    @more = @posts.any? && @newsgroup.posts.where('number < ?', @posts.last.number).any?
  end
  
  def show
    @post_was_unread = @post.mark_read_for_user(@current_user)
    get_next_unread_post if @post_was_unread
  end
  
  def new
    @new_post = Post.new(:newsgroup => @newsgroup)
    if @post
      @new_post.subject = 'Re: ' + @post.subject.sub(/^Re: ?/, '')
      @new_post.body = @post.quoted_body
    end
  end
  
  def create
    if params[:post][:subject].blank?
      @error_text = "You must enter a subject line for your post." and return
    end
    
    newsgroup = @newsgroups.find_by_name(params[:post][:newsgroup])
    if newsgroup.nil?
      @error_text = "The newsgroup you are trying to post to either doesn't exist or doesn't allow posting." and return
    end
    
    reply_newsgroup = reply_post = nil
    if params[:post][:reply_newsgroup]
      reply_newsgroup = Newsgroup.find_by_name(params[:post][:reply_newsgroup])
      reply_post = Post.where(:newsgroup => params[:post][:reply_newsgroup],
        :number => params[:post][:reply_number]).first
      if reply_post.nil?
        @error_text = "The post you are trying to reply to doesn't exist; it may have been canceled. Try refreshing the newsgroup." and return
      end
    end
    
    post_string = Post.build_message(
      :user => @current_user,
      :newsgroup => newsgroup,
      :subject => params[:post][:subject],
      :body => params[:post][:body],
      :reply_post => reply_post
    )
    
    begin
      Net::NNTP.start('news.csh.rit.edu') do |nntp|
        nntp.post(post_string)
      end
    rescue Net::NNTPError
      @error_text = 'NNTP Error: ' + $!.message
    end
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
      @newsgroups = Newsgroup.where(:status => 'y')
    end
end
