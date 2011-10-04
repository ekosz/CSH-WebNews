document.title = '<%= j home_page_title %>'
$('#next_unread').attr('href', '<%= next_unread_href %>')
$('#group_view').html '<%= j render('dashboard') %>'
$('#post_view').empty()
