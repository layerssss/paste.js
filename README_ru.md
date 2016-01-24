# paste.js

`paste.js` это интерфейс для чтения информации (текст / изображение) из буфера обмена в различных браузерах. Он также содержит немного браузерных хаков.


## Совместимость

|                              | IE11 | Firefox 33 | Chrome 38 | Safari | Opera |
|------------------------------|------|------------|-----------|--------|-------|
| pasteText (non-inputable)    | ok   | ok         | ok        | ok     | ok    |
| pasteText (textarea)         | ok   | ok         | ok        | ok     | ok    |
| pasteText (contenteditable)  | ok   | ok         | ok        | ok     | ok    |
| pasteImage (non-inputable)   | ok   | ok         | ok        |        |       |
| pasteImage (textarea)        | ok   | ok         | ok        |        |       |
| pasteImage (contenteditable) | ok   | ok         | ok        |        |       |

## Использование

```js
// jQuery необходим

// для вставки в обычный элемент, текстовое поле или редактируемый элемент
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

## Допольнительно

Смотрите [этот пример](http://micy.in/paste.js/)
