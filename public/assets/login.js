function togglePasswordField(field, toggleButton) {
	var type = field.attr('type') === 'password' ? 'text' : 'password';
	field.attr('type', type);
	toggleButton.removeClass().addClass(type === 'password'
		? 'fa-solid fa-eye eye_toggle'
		: 'fa-solid fa-eye-slash eye_toggle');
}

function activate_login(form)
{	var loginPassword = $('#password');
	$('#toggleLoginPassword').on('click', function() {
		togglePasswordField(loginPassword, $(this));
	});
}

function validatePassword(passwordField, confirmField)
{	var password = passwordField.val();
	var confirmPassword = confirmField.val();
	var lengthWarning = $('#password_length_warning');
	var matchWarning  = $('#password_match_warning');

	if (password.length < 6) {
		lengthWarning.show();
		matchWarning.hide();
		return false;
	} if (password !== confirmPassword) {
		lengthWarning.hide();
		matchWarning.show();
		return false;
	} else {
		lengthWarning.hide();
		matchWarning.hide();
		return true;
	}
}

function activate_register(form)
{	var passwordField = $('#password');
	var confirmField  = $('#confirm_password');

	$('#togglePassword').on('click', function() {
		togglePasswordField(passwordField, $(this));
	});

	$('#toggleConfirmPassword').on('click', function() {
		togglePasswordField(confirmField, $(this));
	});

	form.on('submit', function() {
		return validatePassword(passwordField, confirmField);
	});
}

// dashboard/account script

function activate_account_settings(form) {
	const emailInput    = $('#change_email_input');
	const originalEmail = emailInput.val();

	emailInput.on('input', function () {
		const isEmailChanged = emailInput.val() !== originalEmail;
		changeEmailButton.toggleClass('changed', isEmailChanged);
	});

	$('#change_email_button').on('click', function (event) {
		if(changeEmailButton.hasClass('changed')) {
			// prevent page to reload when form clicked
			event.preventDefault();
		
			// Must make AJAX to call server API later
			alert('Change email button clicked');
		}
	});

	$('#delete_account_button').on('click', function()  {
		if(confirm("Are you sure you want to delete your account?")) {
			// Must call server API to delete user account later

			// Implement account deletion logic here
			alert("Account deleted successfully!");
		}
	});
}


$(document).ready(function() {
	var form = $("form#register");
	if(form.length) { activate_register(form) }

	form = $("form#login");
	if(form.length) { activate_login(form) }

	form = $("form#change_account");
	if(form.length) { activate_account_settings(form) }
})

