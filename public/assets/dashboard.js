
function activate_service_selector(form) {
	$("SELECT#service", form).on('change', function () {
		$(this).find('OPTION:selected').each( function(index, service) {
			var page = '/dashboard/service/' + $(service).val();
console.log("LOAD " + page);
			$("IFRAME#service-window").attr('src', page);
		} );
	} );
}

$(document).ready(function() {
	$("form#service-selector").map(function () { activate_service_selector($(this)) });
})

