passwords = {} # cache for passwords retrieved by AJAX

ready = () ->
  # console.log "ready"
  $('#cookies-information-close-button').click ->
    ok_with_cookies()
  $('.highlightable').hover(
    -> 
      $(this).addClass('highlight')
      item = $(this).find('.password')
      item_id = item.attr('id')
      unless item.length == 0
        if passwords[item_id]
          # password is in cache
          item.text(passwords[item_id]) 
          item.attr('showing', true) 
          item.fadeIn(100)
        else
          unless item.attr('processing')
            # must get it via AJAX
            item.attr('processing', true)
            $.ajax
              url: '/_aj/password'
              type: 'get'
              data: item_id
              context: item
              success: (data) ->
                passwords[item_id] = data
                unless item.attr('showing') 
                  $(this).text(data)
                  $(this).attr('processing', false)
                  $(this).fadeIn(100)
              error: ->
                alert "Can't contact to the server"
    -> 
      $(this).find('.password').text("")
      $(this).find('.password').attr('showing', false) 
      $(this).removeClass('highlight')
      $(this).find('.password').fadeOut(100)
  )

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
