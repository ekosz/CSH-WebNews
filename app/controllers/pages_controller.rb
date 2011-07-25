class PagesController < ApplicationController
  def home
    respond_to do |wants|
      wants.html do
        if @current_user.nil?
          @current_user = User.create!(
            :username => ENV['WEBAUTH_USER'],
            :real_name => ENV['WEBAUTH_LDAP_CN'],
            :preferences => {}
          )
          @new_user = true
        end
      end
      
      wants.js do
        
      end
    end
  end
end
