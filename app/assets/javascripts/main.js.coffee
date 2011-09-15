@chunks = {}
@check_new_delay = 15000
@check_new_retry_delay = 5000
@draft_save_interval = 2000
window.active_navigation = false
window.active_scroll_load = false
window.active_check_new = false
window.draft_interval_func = false

jQuery.fn.outerHTML = ->
  $('<div>').append(this.eq(0).clone()).html()

@set_draft_interval = ->
  $('a.resume_draft').show()
  window.draft_interval_func = setInterval (->
    localStorage['draft_html'] = $('#dialog').outerHTML()
    localStorage['draft_form'] = JSON.stringify($('#dialog form').serializeArray())
  ), draft_save_interval

@clear_draft_interval = ->
  clearInterval(window.draft_interval_func)

@toggle_thread_expand = (tr) ->
  if tr.find('.expandable').length > 0
    tr.find('.expandable').removeClass('expandable').addClass('expanded')
    for child in tr.nextUntil('[data-level=' + tr.attr('data-level') + ']')
      break if parseInt($(child).attr('data-level')) < parseInt(tr.attr('data-level'))
      $(child).show()
      $(child).find('.expandable').removeClass('expandable').addClass('expanded')
  else if tr.find('.expanded').length > 0 and tr.hasClass('selected')
    tr.find('.expanded').removeClass('expanded').addClass('expandable')
    for child in tr.nextUntil('[data-level=' + tr.attr('data-level') + ']')
      break if parseInt($(child).attr('data-level')) < parseInt(tr.attr('data-level'))
      $(child).hide()
      $(child).find('.expanded').removeClass('expanded').addClass('expandable')

window.onhashchange = ->
  if location.hash.substring(0, 3) == '#!/'
    window.active_navigation.abort() if window.active_navigation
    window.active_navigation = $.getScript location.hash.replace('#!', '')
    
    new_group = location.hash.split('/')[1]
    loaded_group = $('#groups_list [data-loaded]').attr('data-name')
    if new_group != loaded_group
      if window.active_scroll_load
        window.active_scroll_load.abort()
        window.active_scroll_load = false
      $('#group_view').empty().append(chunks.spinner.clone())
      $('#post_view').empty()
      $('#groups_list [data-loaded]').removeAttr('data-loaded')
      $('#groups_list .selected').removeClass('selected')
      $('#groups_list [data-name="' + new_group + '"]').addClass('selected')

$(document).ready ->
  chunks.spinner = $('#loader .spinner').clone()
  chunks.overlay = $('#loader #overlay').clone()
  chunks.ajax_error = $('#loader #ajax_error').clone()
  $('#loader').remove()
  
  $('a.resume_draft').hide() if not localStorage['draft_form']
  
  if $('#new_user').length > 0
    $('body').append(chunks.overlay.clone())
    $.getScript '/new_user'
  
  if location.hash == '' or location.hash.substring(0, 3) != '#!/'
    location.hash = '#!/home'
  else
    window.onhashchange()
  
  setTimeout (->
    window.active_check_new = $.getScript '/check_new?location=' + encodeURIComponent(location.hash)
  ), check_new_delay

$('a[href="#"]').live 'click', ->
  return false

$('a.new_draft').live 'click', (e) ->
  if localStorage['draft_form'] and not confirm('Really abandon your saved draft and start a new post?')
    e.stopImmediatePropagation()
    return false

$('a[href^="#?/"]').live 'click', ->
  $('body').append(chunks.overlay.clone())
  $.getScript @href.replace('#?', '')
  return false

$('a.mark_read').live 'click', ->
  if window.active_check_new
    window.active_check_new.abort()
    window.active_check_new = false
    setTimeout (->
      window.active_check_new = $.getScript '/check_new?location=' + encodeURIComponent(location.hash)
    ), check_new_delay
  
  selected = $('#groups_list .selected').attr('data-name')
  newsgroup = $(this).attr('data-newsgroup')
  if newsgroup
    group_item = $('#groups_list [data-name="' + newsgroup + '"]')
    group_item.removeClass('unread mine_reply mine_in_thread').find('.unread_count').remove()
    $('#next_unread').attr('href', '#') if $('#groups_list .unread_count').length == 0
  else
    $('#groups_list li').removeClass('unread mine_reply mine_in_thread').find('.unread_count').remove()
    $('#next_unread').attr('href', '#')
  $('#groups_list [data-name="' + selected + '"]').addClass('selected')
  
  if location.hash.match '#!/home'
    $('#group_view').empty().append(chunks.spinner.clone())
    success = -> window.onhashchange()
  else
    $('#posts_list tbody tr').removeClass('unread')
    if window.active_scroll_load
      window.active_scroll_load.abort()
      window.active_scroll_load = false
      success = -> $('#posts_list').scroll()
  
  $.getScript @href.replace('#~', ''), success
  return false

$('a.minimize_draft').live 'click', ->
  localStorage['draft_html'] = $('#dialog').outerHTML()
  localStorage['draft_form'] = JSON.stringify($('#dialog form').serializeArray())

$('a.dialog_cancel').live 'click', ->
  clear_draft_interval()
  $('#overlay').remove()

$('a.clear_draft').live 'click', ->
  localStorage.removeItem('draft_html')
  localStorage.removeItem('draft_form')
  $('a.resume_draft').hide()

$('a.resume_draft').live 'click', ->
  $('body').append(chunks.overlay.clone())
  $('#overlay').append(localStorage['draft_html'])
  for elem in JSON.parse(localStorage['draft_form'])
    $('#dialog form [name="' + elem.name + '"]').val(elem.value)
  $('#post_body').putCursorAtEnd() if $('#post_body').val() != ''
  set_draft_interval()

$('input[type="submit"]').live 'click', ->
  $('#dialog .buttons').hide()
  $('#dialog .loading').text('Working...')
  $('#dialog .errors').text('')

$('a.new_posts').live 'click', ->
  $('#groups_list [data-loaded]').removeAttr('data-loaded')
  window.onhashchange()

$('#posts_list tbody tr').live 'click', ->
  tr = $(this)
  
  if not tr.hasClass('selected')
    location.hash = tr.find('a').attr('href')
  
  toggle_thread_expand(tr)
  
  $('#posts_list .selected').removeClass('selected')
  tr.addClass('selected')
  return false

$(window).resize ->
  if $('#post_view .buttons').length > 0
    $('#post_view .info h3').css('margin-right', $('#post_view .buttons').outerWidth() + 'px')

$('a, input').live 'mousedown', -> this.style.outlineStyle = 'none'
$('a, input').live 'blur', -> this.style.outlineStyle = ''

$(document).ajaxError (event, jqxhr, settings, exception) ->
  if jqxhr.readyState != 0
    if settings.url.match 'check_new'
      $('body').append(chunks.ajax_error.clone()) if $('#ajax_error').length == 0
      window.active_check_new = false
      setTimeout (->
        window.active_check_new = $.getScript '/check_new?location=' + encodeURIComponent(location.hash)
      ), check_new_retry_delay
    else
      alert("An error occurred requesting #{settings.url}\n\nThis might be due to a connection issue on your end, or it might indicate a bug in WebNews. Check your connection and refresh the page. If this error persists, please file a bug report with the steps needed to reproduce it.")
