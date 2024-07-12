

$(document).ready(function() {

	// Both on logged-in and unauth pages.  Standard input-group layout
	
	$('INPUT[type="password"]').each(function () {
		var field  = $(this);
		var toggle = $( $('.eye_toggle', field.parent()) );

		toggle.on('click', function (e) {
			e.preventDefault();
			toggle.removeClass('fa-eye-slash').removeClass('fa-eye');
			if(field.attr('type') === 'password') {
				field.attr('type', 'text');
				toggle.addClass('fa-eye');
			}
			else
			{	field.attr('type', 'password');
				toggle.addClass('fa-eye-slash');
			}
		});
	});

	// Anywhere we can find select boxes which need search
	$('.search-select').select2({theme: 'bootstrap-5'});

	// make alerts closeable
	$('.alert').each(function () {
		var alert = $(this);
		$('.close', alert).on('click', function () { alert.hide() });
	});

	// enable tooltips
	$('[data-bs-toggle="tooltip"]').tooltip();

	// copy-paste text blocks
	$('PRE.copy-code').each(function () {
		var pre = $(this);
		pre.before('<i class="fa-regular fa-copy copier" aria-hidden="true" for="' + pre.attr('id') + '"></i>');
	});

	$('.copier').each(function () {
		var icon = $(this);
		var code = $('PRE#' + icon.attr('for'));
		icon.on('click', function (event) {
			navigator.clipboard.writeText(code.text());
		});
	});
});
