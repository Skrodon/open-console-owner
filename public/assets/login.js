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

// dashboard/user script

function activate_user_setting(form) {
	const currentUserEmail = 'fetchedMail@example.com';
	const emailInput = $('#user_change_email_input');
	const changeEmailButton = $('#change_email_button');
	const deleteAccountButton = $('#delete_account_button');

	emailInput.val(currentUserEmail);
	const originalEmail = currentUserEmail;

	emailInput.on('input', function () {
		const isEmailChanged = emailInput.val() !== originalEmail;

		changeEmailButton.toggleClass('changed', isEmailChanged);
	});

	changeEmailButton.click(function (event) {
		if (changeEmailButton.hasClass('changed')) {
			// prevent page to reload when form clicked
			event.preventDefault();
		
			// Must make AJAX to call server API later
			alert('Change email button clicked');
		}
	});

	deleteAccountButton.click(function()  {
		const confirmDelete = confirm("Are you sure you want to delete your account?");
		if (confirmDelete) {
			// Must call server API to delete user account later

			// Implement account deletion logic here
			alert("Account deleted successfully!");
		}
	});
}

////////


$(document).ready(function() {
	//XXX Should only run for register form
	var form = $("form#register");
	if(form.length) { activate_register(form) }

	form = $("form#login");
	if(form.length) { activate_login(form) }

	// user page check if change mail and delete button is loaded
	var changeEmailForm = $('form#change_email_form');
	var deleteAccountButton = $('#delete_account_button');

	if ( changeEmailForm.length && deleteAccountButton.length) {
		activate_user_setting(changeEmailForm);
	}
})

