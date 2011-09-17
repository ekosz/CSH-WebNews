$('#overlay').remove()

<% if @sync_error %>
alert('<%= j @sync_error %>')
<% end %>

$('#groups_list [data-loaded]').removeAttr('data-loaded')
location.hash = '#!<%= posts_path(@post.newsgroup.name) %>'
