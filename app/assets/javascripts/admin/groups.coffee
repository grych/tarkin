@ready = ->
  if $("#groups_table").length > 0
    $("#groups_table").tablesorter({ widgets: ["saveSort", "filter"], widgetOptions: {filter_reset: '#clear-filter', filter_saveFilters: 'true'}})
    $("#groups_table").tablesorterPager({container: $("#pager")})
    $('#groups_table').bind('filterInit', ->
      if $.tablesorter.storage
        f = $.tablesorter.storage( this, 'tablesorter-filters' ) || []
        $.tablesorter.setFilters( this, f, false )
    )
    $('#groups_table .tablesorter-filter')[0].select()

$(document).ready(@ready)
