@chunks = {}
@check_new_delay = 15000
window.active_navigation = false
window.active_scroll_load = false
window.active_check_new = false

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
    $('#dialog_wrapper').remove()
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
  $('#loader').remove()
  
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
    group_item.removeClass().find('.unread_count').remove()
    $('#next_unread').attr('href', '#') if $('#groups_list .unread_count').length == 0
  else
    $('#groups_list li').removeClass().find('.unread_count').remove()
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

$('a.dialog_cancel').live 'click', ->
  $('#overlay').remove()

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

$('a, input').live 'mousedown', -> this.style.outlineStyle = 'none'
$('a, input').live 'blur', -> this.style.outlineStyle = ''

$(document).ajaxError (event, jqxhr, settings, exception) ->
  alert("Error requesting #{settings.url}") if jqxhr.readyState != 0
