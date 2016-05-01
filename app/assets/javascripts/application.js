// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery-tablesorter
//= require jquery-tablesorter/addons/pager/jquery.tablesorter.pager
//= require jquery.turbolinks
//= require jquery_ujs
//= require jquery-ui/effect
//= require jquery-ui/effect-highlight
//= require jquery-ui/effect-pulsate
//= require jquery-ui/autocomplete
//= require foundation
//= require confirm_with_reveal.min
//= require turbolinks
//= require coffee_routes
//= require jquery.shorten
//= require spin
//= require jquery.spin

$(function(){ 
  $(document).foundation({
    reveal : {
      animation: 'fade',
      animation_speed: 100,
      multiple_opened: true,
      close_on_background_click: true
    }
  });
});
$(document).confirmWithReveal();

