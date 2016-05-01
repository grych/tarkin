# $(document).ready(@ready)
$(document).on 'page:change', -> 
  ready()

@passwords = {} # cache for passwords retrieved by AJAX

@ready = () ->
  $('.hidden').hide()
  $('#cookies-information-close-button').click ->
    ok_with_cookies()
  show_hide_passwords()
  $('.favorite-switch').change ->
    favorite_switch($(this))
  $('.password').each ->
    show_password($(this)) if $(this).data('favorite')
  $('#edit-mode-button').click ->
    switch_edit_mode($(this))
  $(document).bind('ajaxError', 'form#new_directory', (event, jqxhr, settings, exception) -> 
    $('.reveal-modal.open.confirm-deletion').foundation('reveal', 'close') # close the confirm reveal
    render_form_errors($.parseJSON(jqxhr.responseText)))   # show errors which cames back from rails
  $('#edit-modal').on 'opened', -> $(this).find('form :input:enabled:visible:first').focus() 
  setup_alert_box()
  $.ajaxSetup
    timeout: 10000
  Sorter.sort '.sortable'
  setup_autocomplete()
  Turbolinks.enableTransitionCache()
  $('.tarkin-description').shorten()
  $("#item_" + $(location).attr('hash').split('#')[1]).effect("highlight", {color: "#4499ff"}, 5000)
  spin_options = 
    lines: 16
    length: 46
    width: 20
    scale: 2.0
    radius: 50
    color: '#000'
    speed: 1.5
    trail: 60
    shadow: true
    hwaccel: true
  $(document).on "page:fetch", ->
    $("body").spin(spin_options)
  $(document).on "page:receive", ->
    $("body").spin(false)

# @ready_with_foundation = () ->
  # TODO: check if all is OK after adding jquery.turbolinks
  # $(document).foundation() # must be re-initialized because of turbolinks
  # ready()

setup_autocomplete = ->
  $('#search').autocomplete
    # appendTo: "#search-container"
    source: api_v1__find_path()
    autoFocus: false # autoFocus to first found element
    minLength: 2
    select: (event, ui) ->
      Turbolinks.visit(ui.item.redirect_to)
  $('#search').focus()
  $(window).scroll ->
    # TODO: decide if autocomplete should disappear while scroll
    # $('#search').autocomplete('close')
    $('.ui-autocomplete.ui-menu').position
      my: 'left top'
      at: 'left bottom'
      of: '#search'


@Sorter = {}
@Sorter.sort = (what, direction) ->
  Sorter.direction = if direction == "desc" then -1 else 1
  $(what).each ->
    sorted = $(this).find("> div[data-sortby]").sort (a, b) ->
      if $(a).data('sortby').toString().toLowerCase() > $(b).data('sortby').toString().toLowerCase() then Sorter.direction else -Sorter.direction
    $(this).append(sorted)

capitalize = (word) -> 
  word.charAt(0).toUpperCase() + word.slice 1

@show_hide_passwords = () ->
  $('.item.highlightable').hover(
    -> show_password_in_row ($(this))
    -> hide_password_in_row($(this))
  )

@setup_alert_box = () ->
  $('#edit-form-close-button').click -> 
    $('#edit-modal').foundation('reveal', 'close')
  alert_box_text "" # clean up the alert box

alert_box_text = (text) ->
  $('#edit-modal-alert-box-text').html(text)
  if text == ""
    $('#edit-modal-alert-box').fadeOut(250)
  else
    $('#edit-modal-alert-box').fadeIn(250)

render_form_errors = (errors) ->
  s = ""
  for x, err of errors
    s += "#{err}. <br>"
  alert_box_text(s)

switch_edit_mode = (button) ->
  button.toggleClass('active')
  $('.favorite-switch').toggle()
  $('.edit-button').toggle()
  $('.buttons-panel').toggle()

favorite_switch = (sw) ->
  $.ajax
    url: "/_aj/switch_favorite"
    type: 'post'
    data: { type: sw.data('type'), id: sw.data('id') }
    success: (data) ->
      $('#favorites-holder').html(data.html)
      $(document).foundation()
    error: ->
      alert "Server not responding"

show_password_in_row = (row) ->
  item = row.find('.password')
  show_password(item)

show_password = (item) ->
  unless item.length == 0
    item_id = item.data('id')
    if item_id
      if passwords[item_id]
        # password is in cache
        item.text(passwords[item_id]) 
        item.attr('showing', true) 
        item.fadeIn(100)
      else
        # must get it via AJAX
        unless item.attr('processing')
          item.attr('processing', true)
          get_password(item)

hide_password_in_row = (row) ->
  sw = row.find('.favorite-switch')
  item = row.find('.password')
  unless item.length == 0 
    unless sw.is(':checked')
      item.fadeOut(100, -> item.empty())
      item.attr('showing', false) 

get_password = (item) ->
  $.ajax
    url: api_v1__password_path(format: 'json', id: item.data('id'))
    type: 'get'
    context: item
    success: (data) ->
      passwords[item.data('id')] = data.password
      unless item.attr('showing') 
        $(this).text(data.password)
        $(this).attr('processing', false)
        $(this).fadeIn(100)
    error: ->
      alert "Server not responding"

ok_with_cookies = () ->
  $.ajax
    url: ok_with_cookies_path()
    type: 'post'
    data: true
    error: ->
      alert "Server not responding"

