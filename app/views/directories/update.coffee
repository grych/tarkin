$('#dir_<%= @directory.id %>').html("<%= j render partial: 'directory_row', locals: {directory: @directory} %>")
# @ready()
$('#new-directory-modal').foundation('reveal', 'close')
