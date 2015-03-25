$('#modal-form-holder').html("<%= j render partial: 'form', locals: {modal: true, directory: @directory, item: @item, groups: @groups, action: :create} %>")
@setup_alert_box() # clean up the alert box, enable buttons 
$('#edit-modal').foundation('reveal', 'open')
# $.validator.unobtrusive.parse("#modal-form-holder form")  # to re-enable data-* from jquery_ujs
