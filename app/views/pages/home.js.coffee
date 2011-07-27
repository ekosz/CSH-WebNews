if $('#new_user_head').length == 0
  document.title = 'CSH WebNews'
  $('#groups_list .selected').removeClass('selected')
  $('#group_view').html '<%= j render('dashboard') %>'
  $('#post_view').empty()
