$('#dirs').append("<%= j render partial: 'directory_row', locals: {directory: @directory} %>")
$('.directory .switch').hide() # hide favorite switches
$('#new-directory-modal').foundation('reveal', 'close')
