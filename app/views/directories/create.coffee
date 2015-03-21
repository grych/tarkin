$('#dirs').append("<%= j render partial: 'directory_row', locals: {directory: @directory} %>")
@enable_highlights()
$('#new-directory-modal').foundation('reveal', 'close')
