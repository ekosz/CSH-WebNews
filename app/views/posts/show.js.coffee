select_post = ->
  post_tr = $('#posts_list tr[data-number="<%= @post.number %>"]')
  
  if post_tr.is(':hidden') or post_tr.attr('data-parent') == ''
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
$('#post_view .full.headers').hide()
document.title = '<%= @newsgroup.name %> \u00bb <%= j @post.subject %>'

if $('#posts_list tr[data-number="<%= @post.number %>"]').length == 0
  $('#groups_list .selected').removeClass('selected')
  $('#groups_list li[data-name="<%= @newsgroup.name %>"]').addClass('selected')
  $.getScript '<%= posts_path(@newsgroup.name) %>?showing=<%= @post.number %>', -> select_post()
else
  select_post()
