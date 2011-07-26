class PostsController < ApplicationController
  before_filter :get_newsgroup, :only => [:index, :show]

  def index
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
  
  def get_newsgroup
    @newsgroup = Newsgroup.find_by_name(params[:newsgroup])
  end
end
