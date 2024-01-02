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
	var lengthWarning = $('#password_length_warning', form);
	var matchWarning  = $('#password_match_warning', form);

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
	// get user birthday for later send to sever
	const userBirthDate = $('#user_birth_date');

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

	// languages table
    $(document).on('click', '.remove-link', function (event) {
		event.preventDefault();
		$(this).closest('tr').remove();
	});

	$(document).on('click', '.move-up-link', function (event) {
		event.preventDefault();
		var row = $(this).closest('tr');
		if (row.prev().length > 0) {
			row.insertBefore(row.prev());
		}
	});

	$(document).on('click', '.move-down-link', function (event) {
		event.preventDefault();
		var row = $(this).closest('tr');
		if (row.next().length > 0) {
			row.insertAfter(row.next());
		}
	});

	function isLanguageExists(language) {
		return $('table.table td:first-child').toArray().some(function (element) {
			return $(element).text() === language;
		});
	}
	
	$('#common_languages').change(function () {
		var selectedLanguages = $(this).find('option:selected').map(function() {
			return $(this).text();
		}).get();

	
		if (selectedLanguages.length > 0) {
			$.each(selectedLanguages, function(index, selectedLanguage) {
				if (!isLanguageExists(selectedLanguage)) {
					var newRow = '<tr>' +
						'<td>' + selectedLanguage + '</td>' +
						'<td><a href="#" class="btn btn-danger remove-link">Remove</a></td>' +
						'<td><a href="#" class="btn btn-secondary move-up-link">Move Up</a></td>' +
						'<td><a href="#" class="btn btn-secondary move-down-link">Move Down</a></td>' +
						'</tr>';
					$('table.table').append(newRow);

					$('#common_languages option:contains("' + selectedLanguage + '")').prop('selected', false);
					
				}
			});
		}
	});

	// update avatar
	$('.choose-file-btn').on('click', function (event) {
        event.preventDefault();
        $('#avatar_input').click();
    });

    $('#avatar_input').on('change', function () {
        if (this.files && this.files[0]) {
            var reader = new FileReader();

            reader.onload = function (e) {
                $('.avatar-image').attr('src', e.target.result);
            };

            reader.readAsDataURL(this.files[0]);
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

