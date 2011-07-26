$('#groups_list .selected').removeClass('selected')
$('#groups_list li[data-name="<%= @newsgroup.name %>"]').addClass('selected')
$('#post_view').empty()
$('#group_view').html '<%= j render(:partial => 'group') %>'
$('#posts_list tbody .expanded').removeClass('expanded').addClass('expandable')
$('#posts_list tbody tr[data-level!="1"]').hide()
