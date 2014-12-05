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

```js
// jQuery needed
$('.mydiv, textarea, div[contenteditable]').pastableElement();

$('*').on('pasteImage', function (ev, data){
  console.log("dataURL: " + data.dataURL);
  console.log("width: " + data.width);
  console.log("height: " + data.height);
  console.log(data.blob);
}).on('pasteText', function (ev, data){
  console.log("text: " + data.text);
});
```

more
-----

see [this example](http://micy.in/paste.js/)
