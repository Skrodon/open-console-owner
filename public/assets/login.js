function verify_register_fields(form)
{	var passwordField = $('#password');
	var confirmField = $('#confirm_password');
	var togglePassword = $('#togglePassword');
	var toggleConfirmPassword = $('#toggleConfirmPassword');
	var lengthWarning = $('#password_length_warning');
	var matchWarning  = $('#password_match_warning');

	togglePassword.on('click', function() {
		togglePasswordField(passwordField, togglePassword);
	});

	toggleConfirmPassword.on('click', function() {
		togglePasswordField(confirmField, toggleConfirmPassword);
	});

	function togglePasswordField(field, toggleButton) {
		var type = field.attr('type') === 'password' ? 'text' : 'password';
		field.attr('type', type);
		toggleButton.removeClass().addClass(type === 'password' ? 'fa-solid fa-eye' : 'fa-solid fa-eye-slash');
	}

	function validatePassword() {
		var password = passwordField.val();
		var confirmPassword = confirmField.val();

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

	form.on('submit', function() {
		return validatePassword();
	});
}

$(document).ready(function() {
	//XXX Should only run for register form
	var form = $("form#register");
	if(form.length) { verify_register_fields(form) }
})

