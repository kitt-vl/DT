var AppVM = can.DefineMap.extend({
  bold: function() {
    //document.execCommand( 'bold', null, null );
    var selected = window.getSelection();
    var text = selected.toString();
    if(text) {
      var selRange = selected.getRangeAt(0);
      var tag = document.createElement('b');
      tag.innerHTML = text;
      selRange.deleteContents();
      selRange.insertNode(tag);
      this.copy();
    };
  },
  italic: function() {
    //document.execCommand( 'italic', null, null );
    var selected = window.getSelection();
    var text = selected.toString();
    if(text) {
      var selRange = selected.getRangeAt(0);
      var tag = document.createElement('i');
      tag.innerHTML = text;
      selRange.deleteContents();
      selRange.insertNode(tag);
      this.copy();
    };
  },
  underline: function() {
    //document.execCommand('underline',null,null);
    var selected = window.getSelection();
    var text = selected.toString();
    if(text) {
      var selRange = selected.getRangeAt(0);
      var tag = document.createElement('u');
      tag.innerHTML = text;
      selRange.deleteContents();
      selRange.insertNode(tag);
      this.copy();
    };
  },
  copy: function() {
    document.getElementById('wysiwyg-textarea').value =
    document.getElementById('wysiwyg-div').innerHTML;
  }
});

var appVM = new AppVM();

var template = can.stache.from('wysiwyg-template');
var frag = template(appVM);
document.body.appendChild(frag);
