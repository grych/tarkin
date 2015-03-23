$('#items').append("<%= j render partial: 'item_row', locals: {item: @item} %>")
$('.item .switch').hide() # hide favorite switches
$('#edit-modal').foundation('reveal', 'close')
