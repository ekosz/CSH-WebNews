<% if @error_text %>

$('#dialog .buttons').show()
$('#dialog .loading').text('')
$('#dialog .errors').text('<%= raw j(@error_text) %>')

<% else %>

$('#overlay').remove()
location.hash = '#!<%= post_path(@new_post.newsgroup.name, @new_post.number) %>'

<% end %>
