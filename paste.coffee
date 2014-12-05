### 
paste.js is an interface to read data ( text / image ) from clipboard in different browsers. It also contains several hacks.

https://github.com/layerssss/paste.js
###

$ = window.jQuery
$.paste = (pasteContainer) ->
  console?.log "DEPRECATED: This method is deprecated. Please use $.fn.pastableNonInputable() instead."
  pm = Paste.mountNonInputable pasteContainer
  pm._container
$.fn.$.fn.pastableElement = ->
  for el in @
    if el.tagName is 'TEXTAREA'
      Paste.mountTextarea el;
    else if !!el.hasAttribute 'contenteditable'
      Paste.mountContenteditable el
    else
      Paste.mountNonInputable el
  @

createHiddenEditable = ->
  $(document.createElement 'div')
  .attr 'contenteditable', true
  .css
    width: 1
    height: 1
    position: 'fixed'
    left: -100
    overflow: 'hidden'

class Paste
  # Element to receive final events.
  _target: null

  # Actual element to do pasting.
  _container: null

  @mountNonInputable: (nonInputable)->
    paste = new Paste createHiddenEditable().appendTo(nonInputable), nonInputable
    $(nonInputable).on 'click', => paste._container.focus()

    paste._container.on 'focus', => $(nonInputable).addClass 'pastable-focus'
    paste._container.on 'blur', => $(nonInputable).removeClass 'pastable-focus'


  @mountTextarea: (textarea)->
    # Firefox & IE
    return @mountContenteditable textarea unless window.ClipboardEvent || window.clipboardData
    paste = new Paste createHiddenEditable().insertBefore(textarea), textarea
    ctlDown = false
    $(textarea).on 'keyup', (ev)-> 
      ctlDown = false if ev.keyCode in [17, 224]
    $(textarea).on 'keydown', (ev)-> 
      ctlDown = true if ev.keyCode in [17, 224]
      paste._container.focus() if ctlDown && ev.keyCode == 86
    $(paste._target).on 'pasteImage', =>
      $(textarea).focus()
    $(paste._target).on 'pasteText', =>
      $(textarea).focus()
  
    $(textarea).on 'focus', => $(textarea).addClass 'pastable-focus'
    $(textarea).on 'blur', => $(textarea).removeClass 'pastable-focus'

  @mountContenteditable: (contenteditable)->
    paste = new Paste contenteditable, contenteditable
    
    $(contenteditable).on 'focus', => $(contenteditable).addClass 'pastable-focus'
    $(contenteditable).on 'blur', => $(contenteditable).removeClass 'pastable-focus'


  constructor: (@_container, @_target)->
    @_container = $ @_container
    @_target = $ @_target
    .addClass 'pastable'
    @_container.on 'paste', (ev)=>
      if ev.originalEvent?.clipboardData?
        clipboardData = ev.originalEvent.clipboardData
        if clipboardData.items 
          # Chrome 
          for item in clipboardData.items
            if item.type.match /^image\//
              imgURL = URL.createObjectURL item.getAsFile()
              return @_handleImage imgURL
            if item.type == 'text/plain'
              item.getAsString (string)=>
                @_target.trigger 'pasteText', text: string
        else
          # Firefox & Safari(text-only)
          if -1 != Array.prototype.indexOf.call clipboardData.types, 'text/plain'
            text = clipboardData.getData 'Text'
            @_target.trigger 'pasteText', text: text
          @_checkImagesInContainer (src)=>
            @_handleImage src
      # IE
      if clipboardData = window.clipboardData 
        if (text = clipboardData.getData 'Text')?.length
          @_target.trigger 'pasteText', text: text
        else
          for file in clipboardData.files
            @_handleImage URL.createObjectURL(file)
            @_checkImagesInContainer ->

  _handleImage: (src)->
    loader = new Image()
    loader.onload = =>
        @_target.trigger 'pasteImage',
          image: loader
          width: loader.width
          height: loader.height
    loader.src = src

  _checkImagesInContainer: (cb)->
    timespan = Math.floor 1000 * Math.random()
    img["_paste_marked_#{timespan}"] = true for img in @_container.find('img')
    setTimeout =>
      for img in @_container.find('img')
        cb img.src unless img["_paste_marked_#{timespan}"]
        $(img).remove()
    , 1
