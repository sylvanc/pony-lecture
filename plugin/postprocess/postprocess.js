(function() {
  if( typeof window.addEventListener === 'function' ) {
    $(".seq").css("background", "#ffffff");
    $(".seq").sequenceDiagram({theme: 'hand'});
  }
})();
