# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
# $(document).ready ->
#   setup_page()

ready = () ->
  # console.log "ready"
  $('#cookies-information-close-button').click ->
    ok_with_cookies()

ready_with_foundation = () ->
  $(document).foundation() # bad looking, but it must be re-initialized because of turbolinks
  ready()

ok_with_cookies = () ->
  $.post('/_aj/ok_with_cookies', true, 
    (data) -> 
      unless data['ok']
        alert('Can not save your cookie information, sorry.')
  )

$(document).ready(ready)
$(document).on('page:load', ready_with_foundation)
