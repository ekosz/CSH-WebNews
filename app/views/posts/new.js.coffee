$('#overlay').append('<%= j render('new') %>')
$('#post_body').putCursorAtEnd() if $('#post_body').val() != ''
set_draft_interval()
