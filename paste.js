// Generated by CoffeeScript 1.6.3
(function() {
  var PasteManager;

  $.paste = function(pasteContainer) {
    var pm;
    pm = new PasteManager(pasteContainer);
    return pm.getEventPropagator();
  };

  PasteManager = (function() {
    PasteManager.fallbackPasteArea = null;

    PasteManager.monitoredContainer = null;

    PasteManager.eventPropagotor = null;

    function PasteManager(monitoredContainer) {
      this.monitoredContainer = $(monitoredContainer);
      this.eventPropagotor = $(document.createElement('div')).prop('contenteditable', true).css({
        width: 1,
        height: 1,
        position: 'fixed',
        left: -100,
        overflow: 'hidden'
      });
      this.registerPasteListener();
    }

    PasteManager.prototype.handlePasteEvent = function(ev) {
      var clipboard;
      if (this.hasClipboardSupport(ev)) {
        clipboard = this.getClipboardData(ev);
        if (this.hasClipboardItemsSupport(clipboard)) {
          return this.handleClipboardItems(clipboard);
        } else if (this.hasDataTypes(clipboard)) {
          return this.handleClipboardData(clipboardData);
        } else {
          return this.handlePasteArea(this.fallbackPasteArea);
        }
      }
    };

    PasteManager.prototype.handleClipboardItems = function(clipboardData) {
      var item, reader, _i, _len, _ref, _results,
        _this = this;
      _ref = clipboardData.items;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        if (item.type.match(/^image\//)) {
          reader = new FileReader();
          reader.onload = function(event) {
            return _this.retrieveImageDataFromDomElement(event.target.result, function(data) {
              return _this.triggerEvent('pasteImage', data);
            });
          };
          reader.readAsDataURL(item.getAsFile());
        }
        if (item.type === 'text/plain') {
          _results.push(item.getAsString(function(string) {
            return _this.triggerEvent('pasteText', {
              text: string
            });
          }));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    PasteManager.prototype.handleClipboardData = function(clipboardData) {
      var text, _ref;
      if ((_ref = (text = clipboardData.getData('Text'))) != null ? _ref.length : void 0) {
        return this.triggerEvent('pasteText', {
          text: text
        });
      }
    };

    PasteManager.prototype.handlePasteArea = function() {
      var _this = this;
      return this.findImagesFromEditable(function(data) {
        return _this.fallbackPasteArea.trigger('pasteImage', data);
      });
    };

    PasteManager.prototype.hasClipboardSupport = function(ev) {
      var _ref;
      return (((_ref = ev.originalEvent) != null ? _ref.clipboardData : void 0) != null) || ((typeof window !== "undefined" && window !== null ? window.clipboardData : void 0) != null);
    };

    PasteManager.prototype.hasClipboardItemsSupport = function(clipboardData) {
      return clipboardData.items && clipboardData.items.length;
    };

    PasteManager.prototype.hasDataTypes = function(clipboardData) {
      return clipboardData.types.length;
    };

    PasteManager.prototype.getClipboardData = function(ev) {
      var _ref;
      if (((_ref = ev.originalEvent) != null ? _ref.clipboardData : void 0) != null) {
        return ev.originalEvent.clipboardData;
      } else if ((typeof window !== "undefined" && window !== null ? window.clipboardData : void 0) != null) {
        return window.clipboardData;
      }
    };

    PasteManager.prototype.triggerEvent = function(type, data) {
      return this.eventPropagotor.trigger(type, data);
    };

    PasteManager.prototype.registerPasteListener = function() {
      var _this = this;
      return this.monitoredContainer.on('paste', function(ev) {
        return _this.handlePasteEvent(ev);
      });
    };

    PasteManager.prototype.createHiddenPasteArea = function() {
      var div;
      div = document.createElement('div');
      return this.fallbackPasteArea = $(div).prop('contenteditable', true).css({
        width: 1,
        height: 1,
        position: 'fixed',
        left: -100,
        overflow: 'hidden'
      });
    };

    PasteManager.prototype.retrieveImageDataFromDomElement = function(src, cb) {
      var loader;
      loader = new Image();
      loader.onload = function() {
        var canvas, ctx, dataURL;
        canvas = document.createElement('canvas');
        canvas.width = loader.width;
        canvas.height = loader.height;
        ctx = canvas.getContext('2d');
        ctx.drawImage(loader, 0, 0, canvas.width, canvas.height);
        dataURL = null;
        try {
          dataURL = canvas.toDataURL('image/png');
        } catch (_error) {

        }
        if (dataURL) {
          return cb({
            dataURL: dataURL,
            width: loader.width,
            height: loader.height
          });
        }
      };
      return loader.src = src;
    };

    PasteManager.prototype.findImagesFromEditable = function(callback) {
      var _this = this;
      return setTimeout((function() {
        return _this.fallbackPasteArea.find('img').each(function(i, img) {
          return _this.retrieveImageDataFromDomElement(img.src, callback);
        });
      }), 1);
    };

    PasteManager.prototype.getEventPropagator = function() {
      return this.eventPropagotor;
    };

    return PasteManager;

  })();

}).call(this);
