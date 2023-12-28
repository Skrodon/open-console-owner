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

function activate_register(form)
{	var passwordField = $('#password');
	var confirmField  = $('#confirm_password');

	$('#togglePassword').on('click', function() {
		togglePasswordField(passwordField, $(this));
	});

	$('#toggleConfirmPassword').on('click', function() {
		togglePasswordField(confirmField, $(this));
	});

	function validatePassword() {
		var password = passwordField.val();
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

	form.on('submit', function() {
		return validatePassword();
	});
}

$(document).ready(function() {
	//XXX Should only run for register form
	var form = $("form#register");
	if(form.length) { activate_register(form) }

	form = $("form#login");
	if(form.length) { activate_login(form) }
})

