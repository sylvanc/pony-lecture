(function() {
  if( typeof window.addEventListener === 'function' ) {
    $(".seq").css("background", "#ffffff");
    $(".seq").sequenceDiagram({theme: 'hand'});

    $(".viz").each(function(i) {
      this.innerHTML = Viz(this.textContent, {format: "svg", engine: "dot"});
    });
  }
})();
