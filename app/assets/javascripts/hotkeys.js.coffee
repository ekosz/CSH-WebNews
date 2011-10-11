$ ->
  $ns = $("#posts_list")    # Namespace
  ts = 'tr[data-level="1"]' # Topic Selector
  ss = 'tr.selected'        # Selected Selector
  $(document).keydown (e) ->
    return if isTyping(e) 

    code = if e.keyCode then e.keyCode else e.which # X Browser Support
    switch code
      when 74 # j/J
        if e.shiftKey # J
          # Click next topic
          $ns.find(ss).next(ts).click()
        else if e.ctrlKey # ^j
          # Go to next group
          $("#groups_list li.selected").next('li').click()
        else          # j
          # Click the next row from the one that is selected
          $ns.find(ss).next('tr').click() 
      when 75 # k/K
        if e.shiftKey # K
          # Go to previous topic
          $ns.find(ss).prev(ts).prev(ts).click()
        else if e.ctrlKey # ^k
          # Go to previous group
          $("#groups_list li.selected").prev('li').click()
        else          # k
          # Go to previous row
          $ns.find(ss).prev('tr').click()
      when 78         # n
        # Go to Next Unread
        $("#next_unread").click()
      when 79 # o/O
        if e.shiftKey # O
          # Close the current topic
          $ns.find(ss).prev(ts).click()
        else          # o
          # Open/Close the selected row
          $ns.find(ss).click()
      when 82 # r/R
        if e.shiftKey # R
          # Mark all as read
          $("#toolbar .mark_read").click()
        else          # r
          # Mark all in group read
          $("#group_view .mark_read").click()

    false # Prevent Default

# Don't interrupt the user typing a message
isTyping = (e) ->
  element = null
  # X Browser Support
  if e.target 
    element = e.target
  else if e.srcElement 
    element = e.srcElement

  if element.nodeType == 3 
    element = element.parentNode

  if(element.tagName == 'INPUT' || element.tagName == 'TEXTAREA')
    return true
  else
    return false
  
