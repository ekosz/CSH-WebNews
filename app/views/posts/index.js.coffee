<% if @full_layout %>

<% if not @showing %>
document.title = '<%= @search_mode ? 'Search Results' : @newsgroup.name %>'
<% if not @not_found %>$('#post_view').empty()<% end %>
<% end %>

if <%= @showing ? 'true' : 'false' %> or <%= @search_mode ? 'true' : 'false' %> or
    $('#groups_list li[data-loaded]').attr('data-name') != '<%=
      @search_mode ? 'this_is_irrelevant' : @newsgroup.name %>'

  <% if not @search_mode %>
  $('#groups_list li[data-name="<%= @newsgroup.name %>"]').attr('data-loaded', 'true')
  <% end %>
  
  $('#group_view').html '<%= j render(:partial => 'posts_list', :layout => 'list_layout') %>'
  
  $('#posts_list tbody .expanded').removeClass('expanded').addClass('expandable')
  $('#posts_list tbody tr[data-level!="1"]').hide()
  for unread in $('#posts_list tbody .unread[data-level!="1"]')
    toggle_thread_expand $($(unread).prevAll('[data-level="1"]')[0])
  
  $('#posts_list').scroll ->
    view_height = $(this).height()
    content_height = this.scrollHeight
    scroll_top = $(this).scrollTop()
    needs_load = not ( window.active_scroll_load or $('#posts_load').attr('data-nomore') )
    
    if needs_load and scroll_top + view_height > content_height - 600
      window.active_scroll_load = $.getScript '<%= raw j(
          @search_mode ? request.fullpath + '&' : posts_path(@newsgroup.name) + '?'
        ) %>from=' +
        encodeURIComponent( $('#posts_list tbody tr[data-level="1"]').last().attr('data-date') )
  
  $('#posts_list').scroll()
  
else
  $('#posts_list').scrollTop(0)
  $('#posts_list .selected').removeClass('selected')

<% else %>

$('#posts_list tbody').append '<%= j render(:partial => 'posts_list') %>'

from_tr = $('#posts_list tr[data-date="<%= @from %>"]').nextAll('[data-level="1"]').first()
from_tr.nextAll().andSelf().find('.expanded').removeClass('expanded').addClass('expandable')
from_tr.nextAll('[data-level!="1"]').hide()
for unread in from_tr.nextAll('.unread[data-level!="1"]')
  toggle_thread_expand $($(unread).prevAll('[data-level="1"]')[0])

window.active_scroll_load = false

<% if @more %>
$('#posts_list').scroll()
<% else %>
$('#posts_load').attr('data-nomore', 'true')
$('#posts_load th').removeClass('spinner').text("No more posts!")
<% end %>

<% end %>
