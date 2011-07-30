class UsersController < ApplicationController
  def edit
  end
  
  def update
    @current_user.update_attributes(params[:user])
  end
end
