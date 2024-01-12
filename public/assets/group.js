function send_instruction(form, data, endpoint, how, success) {
    var action = '/dashboard/' + endpoint + '/' + $('#identifier', form).val() + '?' + how;

    $.ajax({
        type: 'POST',
        url: action,
        data: data,
        dataType: 'json',
        success: function (response) {
            process_errors_and_warnings(form, response);
            update_form_status(form);
            if(response.redirect) { window.location = response.redirect }
			success(response);
        },
        error: function (response) {
            alert(action + ', the server could not be reached: ' + response.status);  //XXX translation
        },
    });
}

function activate_invitation_modal(modal, form) {
	var id     = modal.attr('id');
	var email  = modal.data('email');
	var button = $('A[for="' + id + '"]', form);

	button.on('click', function(event)  {
		event.preventDefault();
		modal.show();
	});

	$('#resend_button', modal).on('click', function () {
		send_instruction(form, { email: email }, 'config_invite', 'resend', function () {
console.log('Resend accepted');
		});
	});

	$('#remove_button', modal).on('click', function () {
		send_instruction(form, { email: email }, 'config_invite', 'remove', function () {
			button.parent().parent().remove();  // remove the line with the invitation
		});
	});

	$('button', modal).on('click', function () { modal.hide() });
}

function activate_invite_add(form) {
	var button = $('BUTTON#invite', form);
	var table  = $('TABLE#list_invitations TBODY', form);
	button.on('click', function () {
		event.preventDefault();
		var emails = $('TEXTAREA#invite_emails', form);
		send_instruction(form, { emails: emails.val() }, 'config_invite', 'add', function (answer) {
			for (email of answer.added) {
				table.append('<tr><td>' + email + '</td><td>invited</td></tr>');
			}
			emails.val('');
		});
	});
}

$(document).ready(function() {
	$("form#config_group").map(function () {
		var form = $(this);
		$(".manage_invitation", form).each(function () { activate_invitation_modal( $(this), form ) });
		activate_delete_button(form);
		activate_invite_add(form);
	});
})

