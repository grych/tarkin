# $('#dir_<%= @directory.id %>').html("<%= j render partial: 'directory_row', locals: {directory: @directory} %>")
$('#directory-row-content-holder_<%=@directory.id%>').html("<%= j render partial: 'directory_row_content', locals: {directory: @directory} %>")
$('#edit-modal').foundation('reveal', 'close')
