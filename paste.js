/* 
paste.js is an interface to read data ( text / image ) from clipboard in different browsers. It also contains several hacks.

https://github.com/layerssss/paste.js
 */

(function() {
  var $, Paste, createHiddenEditable;

  $ = window.jQuery;

  $.paste = function(pasteContainer) {
    var pm;
    if (typeof console !== "undefined" && console !== null) {
      console.log("DEPRECATED: This method is deprecated. Please use $.fn.pastableNonInputable() instead.");
    }
    pm = Paste.mountNonInputable(pasteContainer);
    return pm._container;
  };

  $.fn.pastableElement = function() {
    var el, _i, _len;
    for (_i = 0, _len = this.length; _i < _len; _i++) {
      el = this[_i];
      if (el.tagName === 'TEXTAREA') {
        Paste.mountTextarea(el);
      } else if (!!el.hasAttribute('contenteditable')) {
        Paste.mountContenteditable(el);
      } else {
        Paste.mountNonInputable(el);
      };
    };
    return this;
  };

  createHiddenEditable = function() {
    return $(document.createElement('div')).attr('contenteditable', true).css({
      width: 1,
      height: 1,
      position: 'fixed',
      left: -100,
      overflow: 'hidden'
    });
  };

  Paste = (function() {

    // Element to receive final events.
    Paste.prototype._target = null;

    // Actual element to do pasting.
    Paste.prototype._container = null;

    Paste.mountNonInputable = function(nonInputable) {
      var paste;
      paste = new Paste(createHiddenEditable().appendTo(nonInputable), nonInputable);
      $(nonInputable).on('click', (function(_this) {
        return function() {
          return paste._container.focus();
        };
      })(this));
      paste._container.on('focus', (function(_this) {
        return function() {
          return $(nonInputable).addClass('pastable-focus');
        };
      })(this));
      return paste._container.on('blur', (function(_this) {
        return function() {
          return $(nonInputable).removeClass('pastable-focus');
        };
      })(this));
    };

    // Firefox & IE
    Paste.mountTextarea = function(textarea) {
      var ctlDown, paste;
      if (!(window.ClipboardEvent || window.clipboardData)) {
        return this.mountContenteditable(textarea);
      }
      paste = new Paste(createHiddenEditable().insertBefore(textarea), textarea);
      ctlDown = false;
      $(textarea).on('keyup', function(ev) {
        var _ref;
        if ((_ref = ev.keyCode) === 17 || _ref === 224) {
          return ctlDown = false;
        }
      });
      $(textarea).on('keydown', function(ev) {
        var _ref;
        if ((_ref = ev.keyCode) === 17 || _ref === 224) {
          ctlDown = true;
        }
        if (ctlDown && ev.keyCode === 86) {
          return paste._container.focus();
        }
      });
      $(paste._target).on('pasteImage', (function(_this) {
        return function() {
          return $(textarea).focus();
        };
      })(this));
      $(paste._target).on('pasteText', (function(_this) {
        return function() {
          return $(textarea).focus();
        };
      })(this));
      $(textarea).on('focus', (function(_this) {
        return function() {
          return $(textarea).addClass('pastable-focus');
        };
      })(this));
      return $(textarea).on('blur', (function(_this) {
        return function() {
          return $(textarea).removeClass('pastable-focus');
        };
      })(this));
    };

    Paste.mountContenteditable = function(contenteditable) {
      var paste;
      paste = new Paste(contenteditable, contenteditable);
      $(contenteditable).on('focus', (function(_this) {
        return function() {
          return $(contenteditable).addClass('pastable-focus');
        };
      })(this));
      return $(contenteditable).on('blur', (function(_this) {
        return function() {
          return $(contenteditable).removeClass('pastable-focus');
        };
      })(this));
    };

    function Paste(_container, _target) {
      this._container = _container;
      this._target = _target;
      this._container = $(this._container);
      this._target = $(this._target).addClass('pastable');
      this._container.on('paste', (function(_this) {
        return function(ev) {
          var clipboardData, file, item, reader, text, _i, _j, _len, _len1, _ref, _ref1, _ref2, _ref3, _results;
          if (((_ref = ev.originalEvent) != null ? _ref.clipboardData : void 0) != null) {
            clipboardData = ev.originalEvent.clipboardData;
            if (clipboardData.items) {

              // Chrome
              _ref1 = clipboardData.items;
              for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
                item = _ref1[_i];
                if (item.type.match(/^image\//)) {
                  var imgURL = URL.createObjectURL(item.getAsFile());
                  return _this._handleImage(imgURL);
                }
                if (item.type === 'text/plain') {
                  item.getAsString(function(string) {
                    return _this._target.trigger('pasteText', {
                      text: string
                    });
                  });
                }
              }
            } else {

              // Firefox & Safari(text-only)
              if (-1 !== Array.prototype.indexOf.call(clipboardData.types, 'text/plain')) {
                text = clipboardData.getData('Text');
                _this._target.trigger('pasteText', {
                  text: text
                });
              }
              _this._checkImagesInContainer(function(src) {
                return _this._handleImage(src);
              });
            }
          }

          // IE
          if (clipboardData = window.clipboardData) {
            if ((_ref2 = (text = clipboardData.getData('Text'))) != null ? _ref2.length : void 0) {
              return _this._target.trigger('pasteText', {
                text: text
              });
            } else {
              _ref3 = clipboardData.files;
              _results = [];
              for (_j = 0, _len1 = _ref3.length; _j < _len1; _j++) {
                file = _ref3[_j];
                _this._handleImage(URL.createObjectURL(file));
                _results.push(_this._checkImagesInContainer(function() {}));
              }
              return _results;
            }
          }
        };
      })(this));
    }

    Paste.prototype._handleImage = function(src) {
      var loader;
      loader = new Image();
      loader.onload = (function(_this) {
        return function() {
          return _this._target.trigger('pasteImage', {
            image: loader,
            width: loader.width,
            height: loader.height
          });
        };
      })(this);
      return loader.src = src;
    };

    Paste.prototype._checkImagesInContainer = function(cb) {
      var img, timespan, _i, _len, _ref;
      timespan = Math.floor(1000 * Math.random());
      _ref = this._container.find('img');
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        img = _ref[_i];
        img["_paste_marked_" + timespan] = true;
      }
      return setTimeout((function(_this) {
        return function() {
          var _j, _len1, _ref1, _results;
          _ref1 = _this._container.find('img');
          _results = [];
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            img = _ref1[_j];
            if (!img["_paste_marked_" + timespan]) {
              cb(img.src);
            }
            _results.push($(img).remove());
          }
          return _results;
        };
      })(this), 1);
    };

    return Paste;

  })();

}).call(this);
