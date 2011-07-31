spinner = overlay = null
active_navigation = null

window.onhashchange = ->
  if location.hash.substring(0, 3) == '#!/'
    $('#dialog_wrapper').remove()
    active_navigation.abort() if active_navigation
    active_navigation = $.getScript location.hash.replace('#!', '')
    if not location.hash.match $('#groups_list .selected').attr('data-name')
      $('#group_view').empty().append(spinner.clone())
      $('#post_view').empty()

$(document).ready ->
  spinner = $('#loader .spinner').clone()
  overlay = $('#loader #overlay').clone()
  $('#loader').remove()
  
  if location.hash == '' or location.hash.substring(0, 3) != '#!/'
    location.hash = '#!/home'
  else
    window.onhashchange()
    
  if $('#new_user').length > 0
    $('body').append(overlay.clone())
    $.getScript '/new_user'

$('a[href^="#?/"]').live 'click', ->
  $('body').append(overlay.clone())
  $.getScript @href.replace('#?', '')
  return false

$('a.dialog_cancel').live 'click', ->
  $('#overlay').remove()
  return false

$('#groups_list a').live 'click', ->
  $('#group_view').empty().append(spinner.clone())
  $('#post_view').empty()
  $('#groups_list .selected').removeClass('selected')
  $(this).closest('li').addClass('selected')

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
