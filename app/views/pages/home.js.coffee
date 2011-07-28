document.title = 'CSH WebNews'
$('#groups_list .selected').removeClass('selected')
$('#group_view').html '<%= j render('dashboard') %>'
$('#post_view').empty()
