$('#edit-directory-modal-holder').html("<%= j render partial: 'modal', locals: {modal: true, parent_directory: @parent_directory, editing_directory: @directory, groups: @groups, action: :update} %>")
# @ready()
$('#new-directory-modal').foundation('reveal', 'open')
