

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
	$('.search-select').select2(); // ({theme: 'bootstrap5'});

	// make alerts closeable
	var alertList = document.querySelectorAll('.alert');
	alertList.forEach(function (alert) {
  		new bootstrap.Alert(alert)
	});

});
