function togglePasswordField(field, toggleButton) {
	var type = field.attr('type') === 'password' ? 'text' : 'password';
	field.attr('type', type);
	toggleButton.removeClass().addClass(type === 'password'
		? 'fa-solid fa-eye eye_toggle'
		: 'fa-solid fa-eye-slash eye_toggle');
}

function activate_login(form)
{	var loginPassword = $('#password', form);
	$('#toggleLoginPassword', form).on('click', function() {
		togglePasswordField(loginPassword, $(this));
	});
}

function validatePassword(form, passwordField, confirmField)
{	var password = passwordField.val();
	var confirmPassword = confirmField.val();

	$(".warning", form).hide();

	if(password.length < 6) {
		$('#password_length_warning', form).show();
		return false;
	}
	if(password !== confirmPassword) {
		$('#password_match_warning', form).show();
		return false;
	}

	return true;
}

function activate_register(form)
{	var passwordField = $('#password', form);
	var confirmField  = $('#confirm_password', form);

	$('#togglePassword', form).on('click', function() {
		togglePasswordField(passwordField, $(this));
	});

	$('#toggleConfirmPassword', form).on('click', function() {
		togglePasswordField(confirmField, $(this));
	});

	form.on('submit', function() {
		return validatePassword(form, passwordField, confirmField);
	});
}

// dashboard/account script

function activate_account_settings(form) {
	const emailInput    = $('#change_email_input', form);
	const originalEmail = emailInput.val();
	const deleteModal   = $('#delete_account_confirmation_modal', form);

	emailInput.on('input', function () {
		const isEmailChanged = emailInput.val() !== originalEmail;
		changeEmailButton.toggleClass('changed', isEmailChanged);
	});

	$('#change_email_button', form).on('click', function (event) {
		if(changeEmailButton.hasClass('changed')) {
			// prevent page to reload when form clicked
			event.preventDefault();
		
			// Must make AJAX to call server API later
			alert('Change email button clicked');
		}
	});

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
// in handler:  $self->notify(''), redirect to /
		alert('Account deleted successfully');
	});
}

$(document).ready(function() {
	$("form#register").map(function () { activate_register($(this)) });
	$("form#login").map(function () { activate_login($(this)) });
	$("form#change_account").map(function () { activate_account_settings($(this)) });
})

