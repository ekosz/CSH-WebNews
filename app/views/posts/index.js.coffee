<% if @full_layout %>

<% if not @showing %>
document.title = '<%= @search_mode ? 'Search Results' : @newsgroup.name %>'
$('#next_unread').attr('href', '<%= next_unread_href %>')
<% if not @not_found %>$('#post_view').empty()<% end %>
<% end %>

if <%= @showing ? 'true' : 'false' %> or <%= @search_mode ? 'true' : 'false' %> or
    $('#groups_list li[data-loaded]').attr('data-name') != '<%=
      @search_mode ? 'this_is_irrelevant' : @newsgroup.name %>'

  <% if not @search_mode %>
  $('#groups_list li[data-name="<%= @newsgroup.name %>"]').attr('data-loaded', 'true')
  <% end %>
  
  $('#group_view').html '<%= j render(
    :partial => "posts_list", :layout => "list_layout", :locals => {
      :posts =>
        (@posts_newer ? @posts_newer.reverse : []) +
        (@showing_thread ? [@showing_thread] : []) +
        (@posts_older ? @posts_older : [])
      }
    ) %>'
  
  <% if @more_newer %>
  $('#posts_list_headers').css('line-height', '0')
  <% end %>
  
  $('#posts_list tbody .expanded').removeClass('expanded').addClass('expandable')
  $('#posts_list tbody tr[data-level!="1"]').hide()
  for unread in $('#posts_list tbody .unread[data-level!="1"]')
    toggle_thread_expand $($(unread).prevAll('[data-level="1"]')[0])
  
  $('#posts_list').scroll ->
    if not window.active_scroll_load
      view_height = $(this).height()
      content_height = this.scrollHeight
      scroll_top = $(this).scrollTop()
      needs_older_load = ($('#posts_load_older').length > 0)
      needs_newer_load = ($('#posts_load_newer').length > 0)
      
      if needs_older_load or needs_newer_load
        do_request = false
        request_path = '<%= raw j(
          @search_mode ? request.fullpath + "&" : posts_path(@newsgroup.name) + "?") %>'
          
        if needs_older_load and scroll_top + view_height > content_height - 600
          do_request = true
          request_path += 'from_older=' +
            encodeURIComponent( $('#posts_list tbody tr[data-level="1"]').last().attr('data-date') )
        
        if needs_newer_load and scroll_top < 600
          request_path += '&' if do_request
          do_request = true
          request_path += 'from_newer=' +
            encodeURIComponent( $('#posts_list tbody tr[data-level="1"]').first().attr('data-date') )
        
        if do_request
          window.active_scroll_load = $.getScript request_path
  
  $('#posts_list').scroll()
  
else
  $('#posts_list').scrollTop(0)
  $('#posts_list .selected').removeClass('selected')

<% else %>

<% if @posts_older %>
$('#posts_list tbody').append '<%=
  j render(:partial => "posts_list", :locals => { :posts => @posts_older }) %>'
from_tr = $('#posts_list tr[data-date="<%= @from_older %>"]').nextAll('[data-level="1"]').first()
from_tr.nextAll().andSelf().find('.expanded').removeClass('expanded').addClass('expandable')
from_tr.nextAll('[data-level!="1"]').hide()
for unread in from_tr.nextAll('.unread[data-level!="1"]')
  toggle_thread_expand $($(unread).prevAll('[data-level="1"]')[0])
<% end %>

<% if @posts_newer %>
$('#posts_list tbody').prepend '<%=
  j render(:partial => "posts_list", :locals => { :posts => @posts_newer.reverse }) %>'
from_tr = $('#posts_list tr[data-date="<%= @from_newer %>"]').prevAll('[data-level="1"]').first()
tr_height = from_tr.height()
from_tr.prevAll().andSelf().find('.expanded').removeClass('expanded').addClass('expandable')
from_tr.prevAll('[data-level!="1"]').hide()
from_tr.nextUntil('[data-level="1"]').hide()
extra_rows = 0
for unread in from_tr.nextAll('[data-level="1"]').first().prevAll('.unread[data-level!="1"]')
  extra_rows += toggle_thread_expand $($(unread).prevAll('[data-level="1"]')[0])
$('#posts_list').scrollTop(
  $('#posts_list').scrollTop() + (tr_height * (<%= @posts_newer.length %> + extra_rows))
)
<% end %>

window.active_scroll_load = false

<% if @posts_older and not @more_older %>
$('#posts_load_older').remove()
<% end %>
<% if @posts_newer and not @more_newer %>
$('#posts_load_newer').remove()
$('#posts_list_headers').css('line-height', '')
<% end %>

<% if (@posts_older and @more_older) or (@posts_newer and @more_newer) %>
$('#posts_list').scroll()
<% end %>

<% end %>
