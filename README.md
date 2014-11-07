paste.js
=====

paste.js is an interface to read from clipboard data ( text / image ) in different browsers. Currenttly only tested (and works) under: 

* IE 11 (Windows 7). See hints
* Chrome 32+ (Windows 7 / OSX)
* Firefox 26+ (Windows 7 / OSX). See hints
* Opera 25+ (OSX / Windows?)

Image pasting is NOT working under:
* Safari 7.1 (not working due to cliboardAPI bug, see http://jsfiddle.net/0psu172n/13/ )
* IE10 would need the "hiddenPasteArea" implementation, TODO
* IE6/7/8/9: will never work with JS

usage
-----

```
// jQuery needed. First parameter is the container to watch for paste-events. Your editor or any kind of container
paste = $.paste($('div[contenteditable]');
// paste = $.paste($('textarea');
// paste = $.paste($('textarea', {});
// paste = $.paste($body, {
//   skipImageCallback: (img)-> return $(img).is('.alreadyHandledImage')
// })

//
// define your callbacks, e.g. upload the image
paste.on('pasteImage', function (ev, data){
  console.log("dataURL: " + data.dataURL)
});
paste.on('pasteText', function (ev, data){
  console.log("text: " + data.text)
});

// ... when you don't need it anymore
paste.remove();
```

Settings
-----
Those settings are usually only needed for firefox implementations
* pasteArea: jquery object, optional, falls back to the watched container
* skipImageCallback: function pointer, see firefox hints, used to filter already handled images in the watched container
* deletePastedImage: boolean, Also important for the firefox mode, see hints

Hints
-----
Firefox does yet not implement the clipboardAPI properly (TODO link to bug). Therefore the image is actually pasted into the container itself, then parsed and removed (while triggering the pasteImage event)
This means, e.g. when you are using a WYSIWYG editor, you need to use the settings to set the callback. How to determine, which image is pasted (yet not handled). The image inserted by firefox has no classes, just src - we cannot mark it.
You should therefore rather mark processed image with an property/class or whatever (after you uploaded it to your backend). Be aware, that after this image has been pasted into your content area by firefox, and has bin parsed by the paste.js
it will get deleted in the content (so you can place your own new version, the uploaded one..). Use the settings to avoid this


more
-----

(outdated example, old library)
see [this example](http://micy.in/paste.js/)
