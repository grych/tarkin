$('#item-row-content-holder_<%=@item.id%>').html("<%= j render partial: 'items/item_row_content', locals: {item: @item} %>")
$('#edit-modal').foundation('reveal', 'close')
