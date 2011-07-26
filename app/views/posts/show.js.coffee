$('#posts_list .selected').removeClass('selected')
$('#posts_list tr[data-number="<%= @post.number %>"]').addClass('selected')
$('#post_view').html '<%= j render(@post) %>'
$('#post_view .full.headers').hide()
