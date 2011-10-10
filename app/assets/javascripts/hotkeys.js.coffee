$(document).keydown (e) ->
  switch e.keyCode
    when 74 # j/J
      if e.shiftKey # J
        # Click next topic
        $("tr.selected + tr.topic").click()
      else # j
        # Click the next row from the one that is selected
        $("tr.selected + tr").click() 
    when 75 # k
      if (parent_id = $("tr.selected").data('parent-id'))
        # Go to parent
        $('tr').find("[data-number=#{parent_id}]").click()
      else
        #TODO Go to prevois topic

