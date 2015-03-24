$('#items').append("<%= j render partial: 'item_row', locals: {item: @item} %>")
$('.item .switch').hide() # hide favorite switches
@show_hide_passwords()
$('#edit-modal').foundation('reveal', 'close')
