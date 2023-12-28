
$(document).ready(function(){

	// make alerts closeable
	var alertList = document.querySelectorAll('.alert');
	alertList.forEach(function (alert) {
  		new bootstrap.Alert(alert)
	});

});
