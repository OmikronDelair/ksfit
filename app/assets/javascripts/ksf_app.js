$(function () {

  'use strict';
  var url = 'ksfs/upload'
  $('#ucs_file').fileupload({
    url: url,
    dataType: 'json',
    done: function (e, data) {
      $.each(data.result.files, function (index, file) {
        $('<p/>').text(file.message[0]).attr('data-ucs-info',file.name).appendTo('#ucs-info');
        $('select').val(file.message[1]);
        $('#file_name').val(file.name);
        $('#song_title').val($(':selected').text());
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
