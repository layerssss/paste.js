$.paste = (pasteContainer, settings = {}) ->
  pm = new PasteManager(pasteContainer, settings)
  return pm.getEventPropagator()

class PasteManager
  # those things are only needed for "bad browser implementations" like Firefox and Safari
  @pasteArea = null # (optional, by default @monitoredContainer) this is used, when the browser does not support the clipboardAPI that way, that we can access the image data in the clipboard object (e.g. FF, Safari)
  @skipImageCallback = null # if the image is pasted in your main content, use this image to determine, which is the yet new pasted image (unhandled). Needed for Firefox in e.g. WYSIWYG-Editors
  @deletePastedImage = true # in Firefox mode, the image is pasted into a container with designer mode on. like WYSIWYG. Usually we just catch that image, handle it over to the pasteImage event and delete it in the editor

  # general stuff
  @monitoredContainer = null # thats the container monitored for actual pasting by the user, e.g. the WYSIWYG container, a textarea or a div
  @eventPropagotor = null


  constructor: (monitoredContainer, settings = {})->
    # settings
    @pasteArea = settings.pasteArea if settings?.pasteArea?
    @skipImageCallback = settings.skipImageCallback if settings?.skipImageCallback?
    @deletePastedImage = settings.deletePastedImage if settings?.deletePastedImage?

    @monitoredContainer = $(monitoredContainer)
    @registerPasteListener()

  # main logic when we handle a paste even. Determine what the browser supports and try
  # to use different strategies
  handlePasteEvent: (ev) ->
    if @hasClipboardSupport(ev) # includes all browsers except IE8/9/10
      clipboard = @getClipboardData(ev)
      if @hasClipboardItemsSupport(clipboard) # CHROME only
        @handleClipboardItems(clipboard)
      else if @hasClipboardFilesSupport(clipboard) # CHROME only
        @handleClipboardFiles(clipboard, ev)
      else if @hasDataTypes(clipboard) # SAFARI only (images/text), FF only supports this for text
        @handleClipboardData(clipboard)
      else # FF images
        @handlePasteArea(@pasteArea)

  # [Chrome TEXT/IMAGE] the full clipboardAPI implementation has this items, which let us handle text and images the same way
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

  handleClipboardFiles: (clipboardData, ev) ->
    for file in clipboardData.files
      if file.type.match /^image\//
        reader = new FileReader()
        reader.onload = (event) =>
          @retrieveImageDataFromDomElement event.target.result, (data) =>
            @triggerEvent 'pasteImage', data
        reader.readAsDataURL file
      if file.type == 'text/plain'
        file.getAsString (string) =>
          @triggerEvent 'pasteText', text: string

  # [Safari TEXT/IMAGE, Firefox TEXT] handle "minimalistic" clipboaddata.getData implementations, based on "types"
  handleClipboardData: (clipboardData) ->
    # eventhough SAFARI happens to handle types for images AND, it fails to populate getData('URL')
    # so we cannot access the image data
    # TODO: what about URL
    if (text = clipboardData.getData 'Text')?.length
      @triggerEvent 'pasteText', text: text

  # [Firefox IMAGE] image is pasted to our pasteArea, extrac it
  handlePasteArea: ->
    if !@pasteArea # in t
      @pasteArea = @monitoredContainer
    @findImagesFromEditable (data) =>
      @triggerEvent 'pasteImage', data

  # does the browser implement the clipboardAPI at all
  hasClipboardSupport: (ev) ->
    return ev.originalEvent?.clipboardData? || window?.clipboardData?

  # does the browser expose "items" in the clipboardAPI? This is the more advanced clipboardAPI
  hasClipboardItemsSupport: (clipboardData) ->
    # browser like Chrome support clipboard.items for images and text
    return clipboardData.items && clipboardData.items.length

  hasClipboardFilesSupport: (clipboardData) ->
    # browser like Chrome support clipboard.items for images and text
    return clipboardData.files && clipboardData.files.length
  # fallback, if items are not implemented, this is basically the "minimalistic" clipboardAPI implementation
  # mainly this is yet only useful for text, images are detected, but you cannot access them ( Safari )
  hasDataTypes: (clipboardData) ->
    return clipboardData?.types?.length

  # get clipboarddata of the event
  getClipboardData: (ev) ->
    if ev.originalEvent?.clipboardData? # generial browsers Chrome, FF, Safari
      return ev.originalEvent.clipboardData
    else if window?.clipboardData? # IE does this..
      return window.clipboardData

  triggerEvent: (type, data) ->
    @eventPropagotor.trigger type, data

  registerPasteListener: ->
    @eventPropagotor = $(document.createElement 'div')
    .prop('contenteditable', true)
    .css
        width: 1
        height: 1
        position: 'fixed'
        left: -100
        overflow: 'hidden'
    .appendTo('body')

    @monitoredContainer.on 'paste', (ev) =>
      @handlePasteEvent(ev)

  # TODO: this is not needed at all anymore?
  createHiddenPasteArea: ->
    div = document.createElement 'div'
    @pasteArea = $(div)
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
      @pasteArea.find('img').each (i, img) =>
        return if(@skipImageCallback && @skipImageCallback(img))
        @retrieveImageDataFromDomElement img.src, callback
        $(img).remove()
    ), 1

  getEventPropagator: ->
    return @eventPropagotor
