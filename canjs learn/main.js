var AppVM = can.DefineMap.extend({
  copy: function() {
    $('#wysiwyg-textarea').text($('#wysiwyg-div').html());
  },
  format: function(tag) {
    var selected = window.getSelection();
    var selRange = selected.getRangeAt(0);

    var df = selRange.cloneContents();
    var div = document.createElement("div");
    div.appendChild(df);
    var text = div.innerHTML;
    console.log(text);

    if(text) {
      // проверка на уже существующее форматирование
      var $div = $(div);


      // добавление форматирования
      var tag = document.createElement(tag);
      tag.innerHTML = text;
      selRange.deleteContents();
      selRange.insertNode(tag);
      this.copy();
    }
  }
});

var appVM = new AppVM();

var template = can.stache.from('wysiwyg-template');
var frag = template(appVM);
document.body.appendChild(frag);
