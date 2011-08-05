spinner = overlay = null
active_navigation = null

window.onhashchange = ->
  if location.hash.substring(0, 3) == '#!/'
    $('#dialog_wrapper').remove()
    active_navigation.abort() if active_navigation
    active_navigation = $.getScript location.hash.replace('#!', '')
    
    selected_group = $('#groups_list .selected').attr('data-name')
    if not selected_group or not location.hash.match selected_group
      $('#group_view').empty().append(spinner.clone())
      $('#post_view').empty()
      $('#groups_list .selected').removeClass('selected')

$(document).ready ->
  window.chunks = {}
  window.chunks.spinner = spinner = $('#loader .spinner').clone()
  window.chunks.overlay = overlay = $('#loader #overlay').clone()
  $('#loader').remove()
  
  if $('#new_user').length > 0
    $('body').append(overlay.clone())
    $.getScript '/new_user'
  
  if location.hash == '' or location.hash.substring(0, 3) != '#!/'
    location.hash = '#!/home'
  else
    window.onhashchange()

$('a[href="#"]').live 'click', ->
  return false

$('a[href^="#?/"]').live 'click', ->
  $('body').append(overlay.clone())
  $.getScript @href.replace('#?', '')
  return false

$('a.dialog_cancel').live 'click', ->
  $('#overlay').remove()

$('input[type="submit"]').live 'click', ->
  @disabled = true

$('#posts_list tbody tr').live 'click', ->
  tr = $(this)
  
  if not tr.hasClass('selected')
    location.hash = tr.find('a').attr('href')
  
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
  
  $('#posts_list .selected').removeClass('selected')
  tr.addClass('selected')
  return false

$('a, input').live 'mousedown', -> this.style.outlineStyle = 'none'
$('a, input').live 'blur', -> this.style.outlineStyle = ''

$(document).ajaxError (event, jqxhr, settings, exception) ->
  alert("Error requesting #{settings.url}") if jqxhr.readyState != 0
