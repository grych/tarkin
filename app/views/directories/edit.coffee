$('#modal-form-holder').html("<%= j render partial: 'form', locals: {modal: true, parent_directory: @parent_directory, editing_directory: @directory, groups: @groups, action: :update} %>")
@setup_alert_box() # clean up the alert box, enable buttons 
$('#edit-modal').foundation('reveal', 'open')
