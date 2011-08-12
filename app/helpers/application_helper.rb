module ApplicationHelper

  def next_unread_href
    if @next_unread_post
      '#!' + post_path(@next_unread_post.newsgroup.name, @next_unread_post.number)
    else
      '#'
    end
  end
  
  def home_page_title
    if @current_user.unread_count > 0
      "(#{@current_user.unread_count}) CSH WebNews"
    else
      'CSH WebNews'
    end
  end

end
