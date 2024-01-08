function activate_account_config(form) {
	const emailInput	= $('#change_email_input', form);
	const originalEmail = emailInput.val();
	const deleteModal   = $('#delete_account_confirmation_modal', form);

	$('#delete_account_button', form).on('click', function(event)  {
		event.preventDefault();
		deleteModal.show();
	});

	$('#cancel_delete_button', form).on('click', function () {
		deleteModal.hide();
	});

	$('#confirm_delete_button', form).on('click', function () {
		deleteModal.hide();
// form.submit()
// in handler:  $self->notify(''), redirect to frontpage
		alert('Account deleted successfully');
	});
}

$(document).ready(function() {
	$("form#config_account").map(function () {
		activate_account_config($(this)) });
})

