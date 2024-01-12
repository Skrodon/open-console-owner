function activate_language_selector(form) {
	var table = $("#langtab", form).first();

	$('.remove-link', table).on('click', function (event) {
		event.preventDefault();
		$(this).closest('tr').remove();
	});

	$('.move-up-link', table).on('click', function (event) {
		event.preventDefault();
		var row = $(this).closest('tr');
		if (row.prev().length > 0) {
			row.insertBefore(row.prev());
		}
	});

	$('.move-down-link', table).on('click', function (event) {
		event.preventDefault();
		var row = $(this).closest('tr');
		if (row.next().length > 0) {
			row.insertAfter(row.next());
		}
	});
}

$(document).ready(function() {
	$("form#config_account").map(function () {
		var form = $(this);
		activate_language_selector(form);
	});
})

