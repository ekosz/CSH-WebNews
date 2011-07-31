class PagesController < ApplicationController
  before_filter :get_newsgroups, :only => :home

  def home
  end
  
  def new_user
  end
end
