$('#items').append("<%= j render partial: 'item_row', locals: {item: @item} %>")
$('.item .switch').hide() # hide favorite switches
@show_hide_passwords()
Sorter.sort '#items.sortable'
$('#edit-modal').foundation('reveal', 'close')
$('#item_<%=@item.id%>[data-sortby]').effect("pulsate", {times: 6}, 3000)
# $('#item_<%=@item.id%>[data-sortby]').effect("highlight", {color: 'red'}, 3000)