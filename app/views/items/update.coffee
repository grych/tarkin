$('#item-row-content-holder_<%=@item.id%>').html("<%= j render partial: 'items/item_row_content', locals: {item: @item} %>")
$('#item_<%=@item.id%>[data-sortby]').data('sortby', '<%=@item.username%>')
Sorter.sort '#items.sortable'
$('#edit-modal').foundation('reveal', 'close')
