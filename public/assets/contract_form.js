
function activate_service_radio(form)
{	var selected = $('DIV#selected-services');
	$('INPUT#all-services',  form).on('click', function () { selected.hide() });
	$('INPUT#some-services', form).on('click', function () { selected.show() });
}

/*
 * Starter
 */

$(document).ready(function() {
	$('form#config-contract').map(function () {
		var form = $(this);
		activate_service_radio(form);
	});
})

