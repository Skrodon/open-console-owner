function activate_delete_button(form) {
	const deleteModal   = $('#delete_account_confirmation_modal', form);

	$('#delete_account_button', form).on('click', function(event)  {
		event.preventDefault();
		deleteModal.show();
	});

	$('#cancel_delete_button', deleteModal).on('click', function () {
		deleteModal.hide();
	});

	$('#confirm_delete_button', deleteModal).on('click', function () {
		deleteModal.hide();

// form.submit()
// in handler:  $self->notify(''), redirect to frontpage

		alert('Account deleted successfully');
	});
}

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
		activate_delete_button(form);
		activate_language_selector(form);
	});
})

