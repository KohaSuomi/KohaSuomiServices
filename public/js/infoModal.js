$('.open-info').click( function(e) {
  e.preventDefault();
  var data_section = $(this).attr('data-section').split('|');
  var section = data_section[0];
  var preference = data_section[1];
  $.getJSON('../info/infotext.json', function(data) {
    var s = data[section];
    $("#infoModal").find("#infoText").html(s[preference]);
  });
});
