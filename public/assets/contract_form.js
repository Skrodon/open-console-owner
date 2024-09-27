
/*
 * Starter
 */

function activate_confirm(form) {
	var annex   = $('INPUT#annex', form);
	var terms   = $('INPUT#terms', form);
	var license = $('INPUT#license', form);
	var sign    = $('BUTTON#sign', form);

	function set_sign () {
		sign.removeAttr('disabled');
		var complete = annex.prop('checked') && terms.prop('checked') && license.prop('checked');
		if(! complete) { sign.attr('disabled', 'disabled') }
	}

	annex.on('click', set_sign);
	terms.on('click', set_sign);
	license.on('click', set_sign);
	set_sign();

	sign.on('click', function () {
		accept_form_data(form, 'save', undefined, function () {});
	});
}

$(document).ready(function() {
	$('form#config-contract').map(function () {
		var form = $(this);
		activate_confirm(form);
	});
})

