# Proxy object for forwarding method calls to the node object inside the page.

class Poltergeist.Node
  @DELEGATES = ['text', 'getAttribute', 'value', 'set', 'setAttribute',
                'removeAttribute', 'isMultiple', 'select', 'tagName',
                'isVisible', 'position', 'trigger', 'parentId', 'clickTest']

  constructor: (@page, @id) ->

  parent: ->
    new Poltergeist.Node(@page, this.parentId())

  for name in @DELEGATES
    do (name) =>
      this.prototype[name] = (arguments...) ->
        @page.nodeCall(@id, name, arguments)

  scrollIntoView: ->
    dimensions = @page.validatedDimensions()
    document   = dimensions.document
    viewport   = dimensions.viewport
    pos        = this.position()

    scroll = { left: dimensions.left, top: dimensions.top }

    adjust = (coord, measurement) ->
      if pos[coord] < 0
        scroll[coord] = Math.max(
          0,
          scroll[coord] + pos[coord] - (viewport[measurement] / 2)
        )

      else if pos[coord] >= viewport[measurement]
        scroll[coord] = Math.min(
          document[measurement] - viewport[measurement],
          scroll[coord] + pos[coord] - viewport[measurement] + (viewport[measurement] / 2)
        )

    adjust('left', 'width')
    adjust('top',  'height')

    if scroll.left != dimensions.left || scroll.top != dimensions.top
      @page.setScrollPosition(scroll)
      pos = this.position()

    pos

  click: ->
    position = this.scrollIntoView()
    test     = this.clickTest(position.left, position.top)

    if test.status == 'success'
      @page.sendEvent('click', position.left, position.top)
    else
      throw new Poltergeist.ClickFailed(test.selector, position)

  dragTo: (other) ->
    position      = this.scrollIntoView()
    otherPosition = other.position()

    @page.sendEvent('mousedown', position.left,      position.top)
    @page.sendEvent('mousemove', otherPosition.left, otherPosition.top)
    @page.sendEvent('mouseup',   otherPosition.left, otherPosition.top)
