@chunks = {}
@check_new_delay = 15000
active_navigation = null

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
    active_navigation.abort() if active_navigation
    active_navigation = $.getScript location.hash.replace('#!', '')
    
    new_group = location.hash.split('/')[1]
    loaded_group = $('#groups_list [data-loaded]').attr('data-name')
    if new_group != loaded_group
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
    $.getScript '/check_new?location=' + encodeURIComponent(location.hash)
  ), check_new_delay

$('a[href="#"]').live 'click', ->
  return false

$('a[href^="#?/"]').live 'click', ->
  $('body').append(chunks.overlay.clone())
  $.getScript @href.replace('#?', '')
  return false

$('a.dialog_cancel').live 'click', ->
  $('#overlay').remove()

$('input[type="submit"]').live 'click', ->
  @disabled = true

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
