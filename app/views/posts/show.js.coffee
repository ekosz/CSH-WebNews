document.title = '<%= @newsgroup.name %> \u00bb <%= @post.subject %>'

post_tr = -> $('#posts_list tr[data-number="<%= @post.number %>"]')

show_post = ->
  $('#posts_list .selected').removeClass('selected')
  post_tr().addClass('selected')
  $('#post_view').html '<%= j render(@post) %>'
  $('#post_view .full.headers').hide()

if $('#groups_list li.selected[data-name="<%= @newsgroup.name %>"]').length == 0
  $('#groups_list .selected').removeClass('selected')
  $('#groups_list li[data-name="<%= @newsgroup.name %>"]').addClass('selected')
  
  $.getScript '<%= posts_path(@newsgroup.name) %>', ->
    parent = post_tr().prevAll('[data-level="1"]:first')
    parent.find('.expandable').removeClass('expandable').addClass('expanded')
    for child in parent.nextUntil('[data-level="1"]')
      $(child).show()
      $(child).find('.expandable').removeClass('expandable').addClass('expanded')
    show_post()
else
  show_post()
