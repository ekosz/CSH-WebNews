<% if @not_found %>

$('#post_view').html '<%= j render('not_found') %>'
document.title = '<%= @newsgroup.name %> \u00bb Post not found!'
if '<%= @newsgroup.name %>' != $('#groups_list [data-loaded]').attr('data-name')
  $.getScript '<%= posts_path(@newsgroup.name) %>?not_found=true'
else
  $('#posts_list .selected').removeClass('selected')

<% else %>

select_post = (showing) ->
  post_tr = $('#posts_list tr[data-id="<%= @post.id %>"]')
  
  if post_tr.is(':hidden') or (showing and post_tr.attr('data-parent') == '')
    parent = if post_tr.is(':hidden') then post_tr.prevAll('[data-level="1"]:first') else post_tr
    parent.find('.expandable').removeClass('expandable').addClass('expanded')
    for child in parent.nextUntil('[data-level="1"]')
      $(child).show()
      $(child).find('.expandable').removeClass('expandable').addClass('expanded')
  
  $('#posts_list .selected').removeClass('selected')
  post_tr.addClass('selected')
  
  view_height = $('#posts_list').height()
  scroll_top = $('#posts_list').scrollTop()
  post_top = post_tr.position().top + scroll_top
  
  if post_top + 20 > scroll_top + view_height or post_top < scroll_top
    $('#posts_list').scrollTop(post_top - (view_height / 2))

$('#post_view').html '<%= j render(@post) %>'
$('#post_view .headers').hide()

<% if not @search_mode %>
document.title = '<%= @newsgroup.name %> \u00bb <%= raw j(@post.subject) %>'
<% end %>

if $('#posts_list tr[data-id="<%= @post.id %>"]').length == 0
  $('#group_view').empty().append(chunks.spinner.clone())
  $.getScript '<%= posts_path(@newsgroup.name) %>?showing=<%= @post.number %>', -> select_post(true)
else
  select_post(false)
  $('#posts_list .selected').removeClass('unread')

<% if @post_was_unread %>
reset_check_timeout()
group = $('#groups_list li[data-name="<%= @newsgroup.name %>"]')
selected = group.hasClass('selected')
group.removeClass()
unread = <%= raw @newsgroup.unread_for_user(@current_user).to_json %>

if unread.count > 0
  group.addClass('unread').addClass(unread.hclass)
  group.find('.unread_count').text(' (' + unread.count + ')')
else
  group.find('.unread_count').remove()
group.addClass('selected') if selected
<% end %>

$('#next_unread').attr('href', '<%= next_unread_href %>')
$(window).resize()

<% end %>