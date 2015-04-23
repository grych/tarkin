@ready = ->
  if $("#users_table").length > 0
    $("#users_table").tablesorter({ widgets: ["saveSort", "filter"], widgetOptions: {filter_reset: '#clear-filter', filter_saveFilters: 'true'}})
    $("#users_table").tablesorterPager({container: $("#pager")})
    $('#users_table').bind('filterInit', ->
      if $.tablesorter.storage
        f = $.tablesorter.storage( this, 'tablesorter-filters' ) || []
        $.tablesorter.setFilters( this, f, false )
    )
    $('#users_table .tablesorter-filter')[0].select()

$(document).ready(@ready)
