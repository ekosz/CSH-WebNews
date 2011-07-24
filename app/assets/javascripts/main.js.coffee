window.onhashchange = ->
  if location.hash.substring(0, 3) == '#!/'
    $.getScript location.hash.replace('#!', '')

$(document).ready ->
  if location.hash == '' or location.hash.substring(0, 3) != '#!/'
    location.hash = '#!/home'
  else
    window.onhashchange()

$(document).ajaxError (event, jqxhr, settings, exception) ->
  alert("Error requesting #{settings.url}")
