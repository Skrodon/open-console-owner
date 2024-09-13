
function activate_service_selector(form) {
	$("SELECT#service", form).on('change', function () {
		$(this).find('OPTION:selected').each( function(index, service) {
			var page = '/dashboard/viewport/' + $(service).val();
			$("IFRAME#service-window").attr('src', page);
		} );
	} );
}

$(document).ready(function() {
	$("form#service-selector").map(function () { activate_service_selector($(this)) });
})

