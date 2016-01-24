paste.js
=====

paste.js is an interface to read data ( text / image ) from clipboard in different browsers. It also contains several hacks.

browser compatibility
-----

|                              | IE11 | Firefox 33 | Chrome 38 | Safari | Opera |
|------------------------------|------|------------|-----------|--------|-------|
| pasteText (non-inputable)    | ok   | ok         | ok        | ok     | ok    |
| pasteText (textarea)         | ok   | ok         | ok        | ok     | ok    |
| pasteText (contenteditable)  | ok   | ok         | ok        | ok     | ok    |
| pasteImage (non-inputable)   | ok   | ok         | ok        |        |       |
| pasteImage (textarea)        | ok   | ok         | ok        |        |       |
| pasteImage (contenteditable) | ok   | ok         | ok        |        |       |

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

see [this example](http://micy.in/paste.js/)
