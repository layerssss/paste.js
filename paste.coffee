###
paste.js is an interface to read data ( text / image ) from clipboard in different browsers. It also contains several hacks.

https://github.com/layerssss/paste.js
###

$ = window.jQuery
$.paste = (pasteContainer) ->
  console?.log "DEPRECATED: This method is deprecated. Please use $.fn.pastableNonInputable() instead."
  pm = Paste.mountNonInputable pasteContainer
  pm._container
$.fn.pastableNonInputable = ->
  for el in @
    continue if el._pastable || $(el).is('textarea, input:text, [contenteditable]')
    Paste.mountNonInputable el
    el._pastable = true
  @
$.fn.pastableTextarea = ->
  for el in @
    continue if el._pastable || $(el).is(':not(textarea, input:text)')
    Paste.mountTextarea el
    el._pastable = true
  @
$.fn.pastableContenteditable = ->
  for el in @
    continue if el._pastable || $(el).is(':not([contenteditable])')
    Paste.mountContenteditable el
    el._pastable = true
  @

dataURLtoBlob = (dataURL, sliceSize=512) ->
  return null unless m = dataURL.match /^data\:([^\;]+)\;base64\,(.+)$/
  [m, contentType, b64Data] = m
  byteCharacters = atob(b64Data)
  byteArrays = []
  offset = 0
  while offset < byteCharacters.length
    slice = byteCharacters.slice(offset, offset + sliceSize)
    byteNumbers = new Array(slice.length)
    i = 0
    while i < slice.length
      byteNumbers[i] = slice.charCodeAt(i)
      i++
    byteArray = new Uint8Array(byteNumbers)
    byteArrays.push byteArray
    offset += sliceSize
  new Blob byteArrays,
    type: contentType

createHiddenEditable = ->
  $(document.createElement 'div')
    .attr 'contenteditable', true
  .attr 'aria-hidden', true
  .attr 'tabindex', -1
  .css
    width: 1
    height: 1
    position: 'fixed'
    left: -100
    overflow: 'hidden'
    opacity: 1e-17

isFocusable = (element, hasTabindex) ->
  # https://github.com/jquery/jquery-ui/blob/master/ui/focusable.js 
  # 
  # * Copyright jQuery Foundation and other contributors
  # * Released under the MIT license.
  # * http://jquery.org/license
  # 
  map = undefined
  mapName = undefined
  img = undefined
  focusableIfVisible = undefined
  fieldset = undefined
  nodeName = element.nodeName.toLowerCase()
  if 'area' == nodeName
    map = element.parentNode
    mapName = map.name
    if !element.href or !mapName or map.nodeName.toLowerCase() != 'map'
      return false
    img = $('img[usemap=\'#' + mapName + '\']')
    return img.length > 0 and img.is(':visible')
  if /^(input|select|textarea|button|object)$/.test(nodeName)
    focusableIfVisible = !element.disabled
    if focusableIfVisible
      # Form controls within a disabled fieldset are disabled.
      # However, controls within the fieldset's legend do not get disabled.
      # Since controls generally aren't placed inside legends, we skip
      # this portion of the check.
      fieldset = $(element).closest('fieldset')[0]
      if fieldset
        focusableIfVisible = !fieldset.disabled
  else if 'a' == nodeName
    focusableIfVisible = element.href or hasTabindex
  else
    focusableIfVisible = hasTabindex
  focusableIfVisible = focusableIfVisible or $(element).is('[contenteditable]')
  focusableIfVisible and $(element).is(':visible')

class Paste
  # Element to receive final events.
  _target: null

  # Actual element to do pasting.
  _container: null

  @mountNonInputable: (nonInputable)->
    paste = new Paste createHiddenEditable().appendTo(nonInputable), nonInputable
    $(nonInputable).on 'click', (ev)=>
      paste._container.focus() unless isFocusable(ev.target, false) or window.getSelection().toString()

    paste._container.on 'focus', => $(nonInputable).addClass 'pastable-focus'
    paste._container.on 'blur', => $(nonInputable).removeClass 'pastable-focus'


  @mountTextarea: (textarea)->
    # Firefox & IE
    return @mountContenteditable textarea if DataTransfer?.prototype && Object.getOwnPropertyDescriptor?.call(Object, DataTransfer.prototype, 'items')?.get
    paste = new Paste createHiddenEditable().insertBefore(textarea), textarea
    ctlDown = false
    $(textarea).on 'keyup', (ev)->
      ctlDown = false if ev.keyCode in [17, 224]
      null
    $(textarea).on 'keydown', (ev)->
      ctlDown = true if ev.keyCode in [17, 224]
      ctlDown = ev.ctrlKey || ev.metaKey if ev.ctrlKey? && ev.metaKey?
      if ctlDown && ev.keyCode == 86
        paste._textarea_focus_stolen = true
        paste._container.focus()
        paste._paste_event_fired = false
        setTimeout =>
          unless paste._paste_event_fired
            $(textarea).focus()
            paste._textarea_focus_stolen = false
        , 1
      null
    $(textarea).on 'paste', =>
    $(textarea).on 'focus', =>
      $(textarea).addClass 'pastable-focus' unless paste._textarea_focus_stolen
    $(textarea).on 'blur', =>
      $(textarea).removeClass 'pastable-focus' unless paste._textarea_focus_stolen
    $(paste._target).on '_pasteCheckContainerDone', =>
      $(textarea).focus()
      paste._textarea_focus_stolen = false
    $(paste._target).on 'pasteText', (ev, data)=>
      curStart = $(textarea).prop('selectionStart')
      curEnd = $(textarea).prop('selectionEnd')
      content = $(textarea).val()
      $(textarea).val "#{content[0...curStart]}#{data.text}#{content[curEnd...]}"
      $(textarea)[0].setSelectionRange curStart + data.text.length, curStart + data.text.length
      $(textarea).trigger 'change'

  @mountContenteditable: (contenteditable)->
    paste = new Paste contenteditable, contenteditable

    $(contenteditable).on 'focus', => $(contenteditable).addClass 'pastable-focus'
    $(contenteditable).on 'blur', => $(contenteditable).removeClass 'pastable-focus'


  constructor: (@_container, @_target)->
    @_container = $ @_container
    @_target = $ @_target
      .addClass 'pastable'
    @_container.on 'paste', (ev)=>
      # return ev.preventDefault() unless ev.currentTarget == ev.target
      @originalEvent = (if ev.originalEvent != null then ev.originalEvent else null)
      @_paste_event_fired = true
      if ev.originalEvent?.clipboardData?
        clipboardData = ev.originalEvent.clipboardData
        if clipboardData.items
          pastedFilename = null
          # Chrome or any other browsers with DataTransfer.items implemented
          @originalEvent.pastedTypes = []
          for item in clipboardData.items
            if item.type.match(/^text\/(plain|rtf|html)/) 
              @originalEvent.pastedTypes.push(item.type)
          for item, _i in clipboardData.items
            if item.type.match /^image\//
              reader = new FileReader()
              reader.onload = (event)=>
                @_handleImage event.target.result, @originalEvent, pastedFilename
              try
                reader.readAsDataURL item.getAsFile()
              ev.preventDefault()
              break
            if item.type == 'text/plain'
              if _i == 0 && clipboardData.items.length > 1 && clipboardData.items[1].type.match /^image\//
                stringIsFilename = true
                fileType = clipboardData.items[1].type
              item.getAsString (string)=>
                if stringIsFilename
                  pastedFilename = string
                  @_target.trigger 'pasteText', text: string, isFilename: true, fileType: fileType, originalEvent: @originalEvent
                else
                  @_target.trigger 'pasteText', text: string, originalEvent: @originalEvent
            if item.type == 'text/rtf'
              item.getAsString (string)=>
                @_target.trigger 'pasteTextRich', text: string, originalEvent: @originalEvent
            if item.type == 'text/html'
              item.getAsString (string)=>
                @_target.trigger 'pasteTextHtml', text: string, originalEvent: @originalEvent
        else
          # Firefox & Safari(text-only)
          if -1 != Array.prototype.indexOf.call clipboardData.types, 'text/plain'
            text = clipboardData.getData 'Text'
            setTimeout =>
              @_target.trigger 'pasteText', text: text, originalEvent: @originalEvent
            , 1
          @_checkImagesInContainer (src)=>
            @_handleImage src, @originalEvent
      # IE
      if clipboardData = window.clipboardData
        if (text = clipboardData.getData 'Text')?.length
          setTimeout =>
            @_target.trigger 'pasteText', text: text, originalEvent: @originalEvent
            @_target.trigger '_pasteCheckContainerDone'
          , 1
        else
          for file in clipboardData.files
            @_handleImage URL.createObjectURL(file), @originalEvent
          @_checkImagesInContainer (src)=>
            @_handleImage src, @originalEvent
      null

  _handleImage: (src, e, name)->
    if src.match /^webkit\-fake\-url\:\/\//
      return @_target.trigger 'pasteImageError',
        message: "You are trying to paste an image in Safari, however we are unable to retieve its data."
    @_target.trigger 'pasteImageStart'
    loader = new Image()
    loader.crossOrigin = "anonymous"
    loader.onload = =>
      canvas = document.createElement 'canvas'
      canvas.width = loader.width
      canvas.height = loader.height
      ctx = canvas.getContext '2d'
      ctx.drawImage loader, 0, 0, canvas.width, canvas.height
      dataURL = null
      try
        dataURL = canvas.toDataURL 'image/png'
        blob = dataURLtoBlob dataURL
      if dataURL
        @_target.trigger 'pasteImage',
          blob: blob
          dataURL: dataURL
          width: loader.width
          height: loader.height,
          originalEvent: e,
          name: name
      @_target.trigger 'pasteImageEnd'
    loader.onerror = =>
      @_target.trigger 'pasteImageError',
        message: "Failed to get image from: #{src}"
        url: src
      @_target.trigger 'pasteImageEnd'
    loader.src = src

  _checkImagesInContainer: (cb)->
    timespan = Math.floor 1000 * Math.random()
    img["_paste_marked_#{timespan}"] = true for img in @_container.find('img')
    setTimeout =>
      for img in @_container.find('img')
        unless img["_paste_marked_#{timespan}"]
          cb img.src
          $(img).remove()
      @_target.trigger '_pasteCheckContainerDone'
    , 1
