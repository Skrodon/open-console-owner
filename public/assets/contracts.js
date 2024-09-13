
function activate_provider_selector(form) {
	var selector = $('SELECT#service-provider');
	selector.on('change', function () {
		var provider = selector.find(':selected').val();
		window.location = '/dashboard/contract?new&provider=' + provider;
	});
}

/*
 * Starter
 */

$(document).ready(function() {
	$('FORM#pick-provider').map(function () {
		var form = $(this);
		activate_provider_selector(form);
	});

})

