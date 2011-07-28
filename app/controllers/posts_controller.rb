class PostsController < ApplicationController
  before_filter :get_newsgroup, :only => [:index, :show]

  def index
    @full_layout = true
    @from = if params[:from]
      @full_layout = false
      params[:from].to_i
    else
      Post.maximum(:number) + 1
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
    @post = Post.where(:number => params[:number], :newsgroup => params[:newsgroup]).first
  end
  
  def new
  end
  
  def create
  end
  
  def destroy
  end
  
  private
  
    def get_newsgroup
      @newsgroup = Newsgroup.find_by_name(params[:newsgroup])
    end
end
