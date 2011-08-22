<% if @error_text %>

$('#dialog .buttons').show()
$('#dialog .loading').text('')
$('#dialog .errors').text('<%= raw j(@error_text) %>')

<% else %>

$('#overlay').remove()

<% if @sync_error_text %>
alert('<%= j @sync_error_text %>')
<% else %>
location.hash = '#!<%= post_path(@new_post.newsgroup.name, @new_post.number) %>'
<% end %>

<% end %>
