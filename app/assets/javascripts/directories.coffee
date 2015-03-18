passwords = {} # cache for passwords retrieved by AJAX

ready = () ->
  # console.log "ready"
  $('#cookies-information-close-button').click ->
    ok_with_cookies()
  $('.highlightable').hover(
    -> 
      $(this).addClass('highlight')
      item = $(this).find('.password')
      unless item.length == 0
        item_id_arr = item.attr('id').match(/item_(\d+)/)
        if item_id_arr
          item_id = item_id_arr[1]
          if passwords[item_id]
            # password is in cache
            item.text(passwords[item_id]) 
            item.attr('showing', true) 
            item.fadeIn(100)
          else
            # must get it via AJAX
            unless item.attr('processing')
              item.attr('processing', true)
              $.ajax
                url: "/_api/v1/_password/#{item_id}"
                type: 'get'
                # data: item_id
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
      $(this).removeClass('highlight')
      sw = $(this).find('.password-switch')
      item = $(this).find('.password')
      unless item.length == 0 
        unless sw.is(':checked')
          item.fadeOut(100, -> item.text(''))
          item.attr('showing', false) 
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
