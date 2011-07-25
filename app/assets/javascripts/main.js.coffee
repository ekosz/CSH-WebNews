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

$(document).ajaxError (event, jqxhr, settings, exception) ->
  alert("Error requesting #{settings.url}")
