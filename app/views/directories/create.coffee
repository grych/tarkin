$('#dirs').append("<%= j render partial: 'directory_row', locals: {directory: @directory} %>")
$('.directory .switch').hide() # hide favorite switches
Sorter.sort '#dirs.sortable'
$('#edit-modal').foundation('reveal', 'close')
$('#dir_<%=@directory.id%>[data-sortby]').effect("pulsate", {times: 6}, 3000)