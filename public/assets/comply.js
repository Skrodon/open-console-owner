
function enabled_stop_go(form) {
	$('DIV#all-fine IMG#sign', form).each(function() {
		var sign    = $(this);
		var stopped = false;
		sign.on('click', function () {
			if(stopped) {
				accept_form_data(form, 'login');
			} else {
				sign.attr('src', '/images/Go_sign.svg');
				stopped = true;
			}
		});
		setTimeout(function () {
			if(! stopped) { accept_form_data(form, 'login') }
		}, 4000);
		$('INPUT, TEXTAREA, SELECT', form).on('change', function () {
			$stopped = true;
			$('DIV#all-fine').remove();
		});
	});
}

$(document).ready(function() {
	$("form#config-comply").map(function () {
		var form = $(this);
		enabled_stop_go(form);
	});
});

