$('#modal-form-holder').html("<%= j render partial: 'user_password', locals: {modal: true, action: :update} %>")
@setup_alert_box() # clean up the alert box, enable buttons
$('#edit-modal').foundation('reveal', 'open')
