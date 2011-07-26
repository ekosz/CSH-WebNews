class PostsController < ApplicationController
  def index
    @newsgroup = Newsgroup.find_by_name(params[:newsgroup])
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
end
