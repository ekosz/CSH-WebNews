<% if @full_layout %>

<% if not @showing %>
document.title = '<%= @newsgroup.name %>'
<% if not @not_found %>$('#post_view').empty()<% end %>
<% end %>

if <%= @showing ? 'true' : 'false' %> or
    $('#groups_list li[data-loaded]').attr('data-name') != '<%= @newsgroup.name %>'

  $('#groups_list li[data-name="<%= @newsgroup.name %>"]').attr('data-loaded', 'true')
  
  $('#group_view').html '<%= j render(:partial => 'posts_list', :layout => 'group') %>'
  
  $('#posts_list tbody .expanded').removeClass('expanded').addClass('expandable')
  $('#posts_list tbody tr[data-level!="1"]').hide()
  for unread in $('#posts_list tbody .unread[data-level!="1"]')
    toggle_thread_expand $($(unread).prevAll('[data-level="1"]')[0])
  
  $('#posts_list').scroll ->
    view_height = $(this).height()
    content_height = this.scrollHeight
    scroll_top = $(this).scrollTop()
    needs_load = not ( $('#posts_load').attr('data-loading') or $('#posts_load').attr('data-nomore') )
    
    if needs_load and scroll_top + view_height > content_height - 600
      $('#posts_load').attr('data-loading', 'true')
      window.active_scroll_load = $.getScript '<%= posts_path(@newsgroup.name) %>?from=' +
          $('#posts_list tbody tr[data-level="1"]').last().attr('data-number')
  
  $('#posts_list').scroll()
  
else
  $('#posts_list').scrollTop(0)
  $('#posts_list .selected').removeClass('selected')

<% else %>

$('#posts_list tbody').append '<%= j render(:partial => 'posts_list') %>'

from_tr = $('#posts_list tr[data-number="<%= @from %>"]')
from_tr.nextAll().find('.expanded').removeClass('expanded').addClass('expandable')
from_tr.nextAll('[data-level!="1"]').hide()
for unread in from_tr.nextAll('.unread[data-level!="1"]')
  toggle_thread_expand $($(unread).prevAll('[data-level="1"]')[0])

$('#posts_load').removeAttr('data-loading')

<% if @more %>
$('#posts_list').scroll()
<% else %>
$('#posts_load').attr('data-nomore', 'true')
$('#posts_load th').removeClass('spinner').text("You've reached the beginning of this newsgroup!")
<% end %>

<% end %>
