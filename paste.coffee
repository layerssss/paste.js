$ = jQuery
readImagesFromEditable = (element, cb)->
  setTimeout (->
    $(element).find('img').each (i, img)->
      getImageData img.src, cb
   ), 1
getImageData = (src, cb)->
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

$.paste = ->
  div = document.createElement 'div'
  div.contentEditable = true
  $(div).css
    width: 1
    height: 1
    position: 'fixed'
    left: -100
    overflow: 'hidden'
    # backgroundColor: '#ccc'
  .on 'paste', (ev)->
    if ev.originalEvent?.clipboardData?
      clipboardData = ev.originalEvent.clipboardData
      if clipboardData.items #webkit
        for item in clipboardData.items
          if item.type.match /^image\//
            reader = new FileReader()
            reader.onload = (event)=>
              getImageData event.target.result, (data)->
                $(div).trigger 'pasteImage', data
            reader.readAsDataURL item.getAsFile()
          if item.type == 'text/plain'
            item.getAsString (string)->
              $(div).trigger 'pasteText', text: string
      else
        if clipboardData.types.length
          if (text = clipboardData.getData 'Text')?.length
            $(div).trigger 'pasteText', text: text
        else
          readImagesFromEditable div, (data)->
            $(div).trigger 'pasteImage', data
    if clipboardData = window.clipboardData # ie
      if (text = clipboardData.getData 'Text')?.length
        $(div).trigger 'pasteText', text: text
      else
        readImagesFromEditable div, (data)->
          $(div).trigger 'pasteImage', data

    setTimeout (->
        $(div).html('')
      ), 2
  return $ div


