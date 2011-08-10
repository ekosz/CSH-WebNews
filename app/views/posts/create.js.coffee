<% if @error_text %>

$('#dialog input[type="submit"]').removeAttr('disabled')
$('#dialog .errors').text('<%= raw j(@error_text) %>')

<% else %>

$('#overlay').remove()

<% end %>
