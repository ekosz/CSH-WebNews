<% if @full_layout %>

$('#groups_list .selected').removeClass('selected')
$('#groups_list li[data-name="<%= @newsgroup.name %>"]').addClass('selected')

<% if not @showing %>$('#post_view').empty()<% end %>
$('#group_view').html '<%= j render(:partial => 'posts_list', :layout => 'group') %>'

$('#posts_list tbody .expanded').removeClass('expanded').addClass('expandable')
$('#posts_list tbody tr[data-level!="1"]').hide()

<% if not @showing %>document.title = '<%= @newsgroup.name %>'<% end %>

$('#posts_list').scroll ->
  view_height = $(this).height()
  content_height = this.scrollHeight
  scroll_top = $(this).scrollTop()
  needs_load = not ( $('#posts_load').attr('data-loading') or $('#posts_load').attr('data-nomore') )
  
  if needs_load and scroll_top + view_height > content_height - 200
    $('#posts_load').attr('data-loading', 'true')
    $.getScript '<%= posts_path(@newsgroup.name) %>?from=' +
        $('#posts_list tbody tr[data-level="1"]').last().attr('data-number')

$('#posts_list').scroll()

<% else %>

$('#posts_list tbody').append '<%= j render(:partial => 'posts_list') %>'

from_tr = $('#posts_list tr[data-number="<%= @from %>"]')
from_tr.nextAll().find('.expanded').removeClass('expanded').addClass('expandable')
from_tr.nextAll('[data-level!="1"]').hide()

$('#posts_load').removeAttr('data-loading')
<% if @more %>
$('#posts_list').scroll()
<% else %>
$('#posts_load').attr('data-nomore', 'true')
$('#posts_load th').removeClass('spinner').text("You've reached the beginning of this newsgroup!")
<% end %>

<% end %>
