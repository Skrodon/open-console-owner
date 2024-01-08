function activate_login(form) {
}

function validatePassword(form, passwordField, confirmField)
{	var password = passwordField.val();
	var confirmPassword = confirmField.val();

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
	var confirmField  = $('#confirm', form);

	$(".warning", form).hide();

	form.on('submit', function() {
		return validatePassword(form, passwordField, confirmField);
	});
}

$(document).ready(function() {
	$("form#register").map(function () { activate_register($(this)) });
	$("form#login").map(function () { activate_login($(this)) });
})

