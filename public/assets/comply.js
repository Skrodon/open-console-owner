
function _check_ready_to_go(progr, response) {
console.log("CHECK READY");
console.log(response);
	if(! response.redirect)
	{	$('DIV.alert', progr).hide();
		$('DIV#progress-incomplete', progr).show();
	}
}

function enabled_stop_go(form) {
	var progr = $('DIV#progress', form);
	var stop  = $('DIV#progress-fine IMG.stop', progr);

	stop.each(function() {
		$(this).on('click', function () {
			$('DIV#progress-fine', progr).hide();
			$('DIV#progress-stopped', progr).show();
		});
	});

	$('IMG.go', progr).each(function () {
		$(this).on('click', function () {
			accept_form_data(form, 'login', {},
				function (form, response) { _check_ready_to_go(progr, response) }
			);
		});
	});

	setTimeout(function () {
		if(stop.is(':visible')) {
			accept_form_data(form, 'login', {},
				function (form, response) { _check_ready_to_go(progr, response) }
			);
	 	}
	}, 4000);

	$('INPUT, TEXTAREA, SELECT', form).on('change', function () {
		$('DIV.alert', progr).hide();
		$('DIV#progress-incomplete', progr).show();
	});
}

$(document).ready(function() {
	$("form#config-comply").map(function () {
		var form = $(this);
		enabled_stop_go(form);
	});
});

