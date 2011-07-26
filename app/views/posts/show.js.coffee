if $('#groups_list li.selected[data-name="<%= @newsgroup.name %>"]').length == 0
  $.ajaxSetup {async: false}
  $.getScript('<%= posts_path(@newsgroup.name) %>')
  $.ajaxSetup {async: true}
  
  tr = $('#posts_list tr[data-number="<%= @post.number %>"]')
  parent = tr.prevAll('[data-level="1"]:first')
  parent.find('.expandable').removeClass('expandable').addClass('expanded')
  for child in parent.nextUntil('[data-level="1"]')
    $(child).show()
    $(child).find('.expandable').removeClass('expandable').addClass('expanded')
  tr.addClass('selected')

$('#post_view').html '<%= j render(@post) %>'
$('#post_view .full.headers').hide()
