# $('#dir_<%= @directory.id %>').html("<%= j render partial: 'directory_row', locals: {directory: @directory} %>")
$('#directory-row-content-holder_<%=@directory.id%>').html("<%= j render partial: 'directory_row_content', locals: {directory: @directory} %>")
$('#dir_<%=@directory.id%>[data-sortby]').data('sortby', '<%=@directory.name%>')
Sorter.sort '#dirs.sortable'
$('#edit-modal').foundation('reveal', 'close')
