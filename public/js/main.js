$( document ).ready(function() {
  var upload_file = function(el){

  };

  console.log( "ready!" );

  var element = $("input#file-upload");
    element.change(function(ev){
      var data = new FormData();

      var input = ev.target;

      $.each(input.files, function(key, value) {
        console.log("file-upload.change() - " + key+" "+value);
        data.append(key, value);
      });

      var id = $("input#id").val();
      var title = $("input#title").val();
      var body = $("textarea#body").text();
      var url = $("input#url").val();

      if(id === undefined) {
        data.append('id',0)
      } else {
        data.append('id',id);
      }
      data.append('title',title);
      data.append('body',body);
      data.append('url',url);

      //set info string
      $("#file-upload-info").text("Загружаем файлы ... ");
      //element.prop("disabled","disabled");

      //upload via ajax
      $.ajax({
        url: '/admin/articles/upload',
        type: 'POST',
        data: data,
        cache: false,
        dataType: 'json',
        processData: false, // Don't process the files
        contentType: false, // Set content type to false as jQuery will tell the server its a query string request
        success: function(data, textStatus, jqXHR){
          //set info string
          $("#file-upload-info").text(data.message);
          //element.removeProp("disabled");
          console.log('data.result : '+data.result);
          $.each(data.result, function(key, val){
            $("#file-upload-result").append("<li><a href=\""+val+"\">"+val+"</a></li>"
          +"<span class='icons'><a class='glyphicon glyphicon-remove' href='/admin/articles/upload/delete/"+id+"/"+data.file_id[key]+"'></a></span>");
          });
          $("input#id").val(data.id);
        },
        error: function(jqXHR, textStatus, errorThrown){
          // Handle errors here
          $("#file-upload-info").text("Ошибка загрузки файлов: "+textStatus);
          element.removeProp("disabled");
          console.log('UPLOAD ERRORS: ' + textStatus);
        }
      });
    }


  );

});
