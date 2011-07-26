class PostsController < ApplicationController
  def index
    @newsgroup = Newsgroup.find_by_name(params[:newsgroup])
  end
  
  def show
  end
  
  def new
  end
  
  def create
  end
  
  def destroy
  end
end
