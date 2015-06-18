$('.row.item[data-type=item][data-id=<%=@item.id%>]').remove()
# close all opened modals
# $('.reveal-modal.open.medium').foundation('reveal', 'close')
$('#edit-modal').foundation('reveal', 'close')
