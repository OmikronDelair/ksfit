/*global $*/

$(function () {

  'use strict';
  var url = 'ksfs/upload'
  $('#ucs_file').fileupload({
    url: url,
    dataType: 'json',
    done: function (e, data) {
      $.each(data.result.files, function (index, file) {
        $('<p/>').text(file.message[0]).attr('data-ucs-info',file.name).appendTo('#ucs-info');

        if (file.message[1] == null){
          $('select').css('display','block');
        }
        else{
          $('select').css('display','none')
                     .val(file.message[1]);
        };

        $('#ucs_filename').val(file.name);
        $('#ucs_body').val(file.file_body);
        $('#ucs_title').val($(':selected').text());
      });
    },
    progressall: function (e, data) {
      var progress = parseInt(data.loaded / data.total * 100, 10);
      $('#progress .progress-bar').css(
        'width',
        progress + '%'
      );
    }
  }).prop('disabled', !$.support.fileInput)
  .parent().addClass($.support.fileInput ? undefined : 'disabled');

});
