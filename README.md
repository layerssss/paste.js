paste.js
=====

paste.js is an interface to read data ( text / image ) from clipboard in different browsers. It also contains several hacks.

browser compatibility
-----

|                              | IE11 | Firefox 33 | Chrome 38 | Safari(10.1) | Opera |
|------------------------------|------|------------|-----------|--------------|-------|
| pasteText (non-inputable)    | ok   | ok         | ok        | ok           | ok    |
| pasteText (textarea)         | ok   | ok         | ok        | ok           | ok    |
| pasteText (contenteditable)  | ok   | ok         | ok        | ok           | ok    |
| pasteImage (non-inputable)   | ok   | ok         | ok        | ok           | ok    |
| pasteImage (textarea)        | ok   | ok         | ok        | ok           | ok    |
| pasteImage (contenteditable) | ok   | ok         | ok        | ok           | ok    |

usage
-----

```
// jQuery needed
$('.mydiv').pastableNonInputable();

$('textarea').pastableTextarea();

$('div[contenteditable]').pastableContenteditable();

$('*').on('pasteImage', function (ev, data){
  console.log("dataURL: " + data.dataURL);
  console.log("width: " + data.width);
  console.log("height: " + data.height);
  console.log(data.blob);
}).on('pasteImageError', function(ev, data){
  alert('Oops: ' + data.message);
  if(data.url){
    alert('But we got its url anyway:' + data.url)
  }
}).on('pasteText', function (ev, data){
  console.log("text: " + data.text);
});
```

more
-----

see [this example](http://layerssss.github.io/paste.js/)

Thanks BrowserStack for providing cross-browser testing environment for this project.

[![browserstack_logo](browserstack_logo.png)](https://browserstack.com/)

license
-----

[The MIT License (MIT)](LICENSE)
