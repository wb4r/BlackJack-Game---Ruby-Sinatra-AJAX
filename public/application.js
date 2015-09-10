$(document).ready(function(){
  player_hit();
  player_stay();
  replay();
});

function player_hit() {
  $(document).on("click", "#hit_form input", function() {
    $.ajax({
      type: 'POST',
      url: '/hit'
    }).done(function(msg){
      $("#game").replaceWith(msg);
    });
    return false;
  });
}

function player_stay() {
  $(document).on("click", "#stay_form input", function() {
    $.ajax({
      type: 'POST',
      url: '/stay'
    }).done(function(msg){
      $("#game").replaceWith(msg);
    });
    return false;
  });
}

function replay() {
  $(document).on("click", "#replay button", function() {
    $.ajax({
      type: 'POST',
      url: '/bet'
    }).done(function(msg){
      $("#game").replaceWith(msg);
    });
    return false;
  });
}
