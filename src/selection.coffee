
class Selection extends Plugin
  constructor: (args...) ->
    super args...
    @sel = document.getSelection()
    @editor = @widget

  _init: ->

  clear: ->
    @sel.removeAllRanges()

  getRange: ->
    if !@editor.inputManager.focused or !@sel.rangeCount
      return null

    return @sel.getRangeAt 0

  selectRange: (range) ->
    @sel.removeAllRanges()
    @sel.addRange(range)

  rangeAtEndOf: (node, range = @getRange()) ->
    return unless range? and range.collapsed

    node = $(node)[0]
    endNode = range.endContainer
    endNodeLength = @editor.util.getNodeLength endNode
    #node.normalize()
    
    if !(range.endOffset == endNodeLength - 1 and $(endNode).contents().last().is('br')) and range.endOffset != endNodeLength
      return false

    if node == endNode
      return true
    else if !$.contains(node, endNode)
      return false

    result = true
    $(endNode).parentsUntil(node).addBack().each (i, n) =>
      nodes = $(n).parent().contents().filter ->
        !(this.nodeType == 3 && !this.nodeValue)
      $lastChild = nodes.last()
      unless $lastChild.get(0) == n or ($lastChild.is('br') and $lastChild.prev().get(0) == n)
        result = false
        return false

    result

  rangeAtStartOf: (node, range = @getRange()) ->
    return unless range? and range.collapsed

    node = $(node)[0]
    startNode = range.startContainer

    if range.startOffset != 0
      return false

    if node == startNode
      return true
    else if !$.contains(node, startNode)
      return false

    result = true
    $(startNode).parentsUntil(node).addBack().each (i, n) =>
      nodes = $(n).parent().contents().filter ->
        !(this.nodeType == 3 && !this.nodeValue)
      result = false unless nodes.first().get(0) == n

    result

  insertNode: (node, range = @getRange()) ->
    return unless range?

    node = $(node)[0]
    range.insertNode node
    @setRangeAfter node

  setRangeAfter: (node, range = @getRange()) ->
    return unless range?

    node = $(node)[0]
    range.setEndAfter node
    range.collapse(false)
    @selectRange range

  setRangeBefore: (node, range = @getRange()) ->
    return unless range?

    node = $(node)[0]
    range.setEndBefore node
    range.collapse(false)
    @selectRange range

  setRangeAtStartOf: (node, range = @getRange()) ->
    node = $(node).get(0)
    range.setEnd(node, 0)
    range.collapse(false)
    @selectRange range

  setRangeAtEndOf: (node, range = @getRange()) ->
    $node = $(node)
    node = $node.get(0)

    if $node.is('pre')
      contents = $node.contents()
      if contents.length > 0
        lastChild = contents.last()
        lastText = lastChild.text()
        if lastText.charAt(lastText.length - 1) is '\n'
          range.setEnd(lastChild[0], @editor.util.getNodeLength(lastChild[0]) - 1)
        else
          range.setEnd(lastChild[0], @editor.util.getNodeLength(lastChild[0]))
      else
        range.setEnd(node, 0)
    else
      nodeLength = @editor.util.getNodeLength node
      nodeLength -= 1 if node.nodeType != 3 and nodeLength > 0 and $(node).contents().last().is('br')
      range.setEnd(node, nodeLength)

    range.collapse(false)
    @selectRange range

  deleteRangeContents: (range = @getRange()) ->
    range.deleteContents()

  breakBlockEl: (el, range = @getRange()) ->
    $el = $(el)
    return $el unless range.collapsed
    range.setStartBefore $el.get(0)
    return $el if range.collapsed
    $el.before range.extractContents()

  save: () ->
    return if @_selectionSaved

    range = @getRange()
    startCaret = $('<span/>').addClass('simditor-caret-start')
    endCaret = $('<span/>').addClass('simditor-caret-end')

    range.insertNode(startCaret[0])
    range.collapse(false)
    range.insertNode(endCaret[0])

    @sel.removeAllRanges()
    @_selectionSaved = true

  restore: () ->
    return false unless @_selectionSaved

    startCaret = @editor.body.find('.simditor-caret-start')
    endCaret = @editor.body.find('.simditor-caret-end')

    if startCaret.length and endCaret.length
      startContainer = startCaret.parent()
      startOffset = startContainer.contents().index(startCaret)
      endContainer = endCaret.parent()
      endOffset = endContainer.contents().index(endCaret)

      if startContainer[0] == endContainer[0]
        endOffset -= 1;

      range = document.createRange()
      range.setStart(startContainer.get(0), startOffset)
      range.setEnd(endContainer.get(0), endOffset)

      startCaret.remove()
      endCaret.remove()
      @selectRange range
    else
      startCaret.remove()
      endCaret.remove()

    @_selectionSaved = false
    range


