$('#modal-form-holder').html("<%= j render partial: 'form', locals: {modal: true, directory: @directory, item: @item, groups: @groups, action: :create} %>")
@setup_alert_box()       # clean up the alert box, enable buttons 
$('#edit-modal').foundation 'reveal', 'open'

