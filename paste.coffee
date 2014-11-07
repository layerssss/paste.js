$.paste = (pasteContainer) ->
  pm = new PasteManager(pasteContainer)
  return pm.getEventPropagator()

class PasteManager
  @fallbackPasteArea = null
  @monitoredContainer = null
  @eventPropagotor = null

  constructor: (monitoredContainer)->
    @monitoredContainer = $(monitoredContainer)
    @eventPropagotor = $(document.createElement 'div')
    .prop('contenteditable', true)
    .css
      width: 1
      height: 1
      position: 'fixed'
      left: -100
      overflow: 'hidden'
    @registerPasteListener()

  # main logic when we handle a paste even. Determine what the browser supports and try
  # to use different strategies
  handlePasteEvent: (ev) ->
    if @hasClipboardSupport(ev) # only chrome for now, probably IE11
     clipboard = @getClipboardData(ev)
     if @hasClipboardItemsSupport(clipboard)
       @handleClipboardItems(clipboard)
     else if @hasDataTypes(clipboard) # for now, only Safari will happen to get here, but wont handle images
       @handleClipboardData(clipboardData)
     else
       @handlePasteArea(@fallbackPasteArea)
  # the full clipboardAPI implementation has this items, which let us handle text and images the same way
  handleClipboardItems: (clipboardData) ->
    for item in clipboardData.items
      if item.type.match /^image\//
        reader = new FileReader()
        reader.onload = (event) =>
          @retrieveImageDataFromDomElement event.target.result, (data) =>
            @triggerEvent 'pasteImage', data
        reader.readAsDataURL item.getAsFile()
      if item.type == 'text/plain'
        item.getAsString (string) =>
          @triggerEvent 'pasteText', text: string

  # handle "minimalistic" clipboaddata.getData implementations, based on "types" (Safari)
  handleClipboardData: (clipboardData) ->
    # yet we only handle Text here
    # TODO: what about URL
    if (text = clipboardData.getData 'Text')?.length
      @triggerEvent 'pasteText', text: text



  # image is pasted to our pasteArea, extrac it
  handlePasteArea:  ->
    @findImagesFromEditable (data) =>
      @fallbackPasteArea.trigger 'pasteImage', data

  # does the browser implement the clipboardAPI at all
  hasClipboardSupport: (ev) ->
    return ev.originalEvent?.clipboardData? || window?.clipboardData?

  # does the browser expose "items" in the clipboardAPI? This is the more advanced clipboardAPI
  hasClipboardItemsSupport: (clipboardData) ->
    # browser like Chrome support clipboard.items for images and text
    return clipboardData.items && clipboardData.items.length

  # fallback, if items are not implemented, this is basically the "minimalistic" clipboardAPI implementation
  # mainly this is yet only useful for text, images are detected, but you cannot access them ( Safari )
  hasDataTypes: (clipboardData) ->
    return clipboardData.types.length

  # get clipboarddata of the event
  getClipboardData: (ev) ->
    if ev.originalEvent?.clipboardData? # generial browsers Chrome, FF, Safari
      return ev.originalEvent.clipboardData
    else if window?.clipboardData? # IE does this..
      return window.clipboardData

  triggerEvent: (type, data) ->
    @eventPropagotor.trigger type, data

  registerPasteListener: ->
    @monitoredContainer.on 'paste', (ev) =>
      @handlePasteEvent(ev)

  createHiddenPasteArea: ->
    div = document.createElement 'div'
    @fallbackPasteArea = $(div)
    .prop('contenteditable', true)
    .css
      width: 1
      height: 1
      position: 'fixed'
      left: -100
      overflow: 'hidden'

  retrieveImageDataFromDomElement: (src, cb)->
    loader = new Image()
    loader.onload = ->
      canvas = document.createElement 'canvas'
      canvas.width = loader.width
      canvas.height = loader.height
      ctx = canvas.getContext '2d'
      ctx.drawImage loader, 0, 0, canvas.width, canvas.height
      dataURL = null
      try
        dataURL = canvas.toDataURL 'image/png'
      catch
      if dataURL
        cb
          dataURL: dataURL
          width: loader.width
          height: loader.height
    loader.src = src

  findImagesFromEditable: (callback)->
    setTimeout ( =>
      @fallbackPasteArea.find('img').each (i, img) =>
        @retrieveImageDataFromDomElement img.src, callback
    ), 1

  getEventPropagator: ->
    return @eventPropagotor