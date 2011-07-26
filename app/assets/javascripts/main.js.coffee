window.onhashchange = ->
  if location.hash.substring(0, 3) == '#!/'
    $('#dialog_wrapper').remove()
    $.getScript location.hash.replace('#!', '')

$(document).ready ->
  if location.hash == '' or location.hash.substring(0, 3) != '#!/'
    location.hash = '#!/home'
  else
    window.onhashchange()
    
$('a[href^="#?/"]').live 'click', ->
  $.getScript @href.replace('#?', '')
  return false
  
$('a.dialog_cancel').live 'click', ->
  $('#dialog_wrapper').remove()
  return false
  
$('#posts_list tr').live 'click', ->
  tr = $(this)
  if tr.find('.expandable').length > 0
    tr.find('.expandable').removeClass('expandable').addClass('expanded')
    for child in tr.nextUntil('[data-level=' + tr.attr('data-level') + ']')
      break if parseInt($(child).attr('data-level')) < parseInt(tr.attr('data-level'))
      $(child).show()
      $(child).find('.expandable').removeClass('expandable').addClass('expanded')
  else if tr.find('.expanded').length > 0
    tr.find('.expanded').removeClass('expanded').addClass('expandable')
    for child in tr.nextUntil('[data-level=' + tr.attr('data-level') + ']')
      break if parseInt($(child).attr('data-level')) < parseInt(tr.attr('data-level'))
      $(child).hide()
      $(child).find('.expanded').removeClass('expanded').addClass('expandable')

$(document).ajaxError (event, jqxhr, settings, exception) ->
  alert("Error requesting #{settings.url}")
