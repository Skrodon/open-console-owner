function send_instruction(form, data, groupid, how, success) {
    var action = '/dashboard/config_member/' + groupid + '?' + how;
	/* Handled in OwnerConsole::Controller::Groups::configMember() */

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

function activate_membership_change(form) {
	form.on('change', '.member', function () {
		var select = $(this);
		$("option:selected", select).each(function () {
			var identid = $(this).val();
			var groupid = $(select).data('groupid');
			send_instruction(form, { identid: identid }, groupid, 'change_identity', function () {
console.log('change identity to ' + identid + " for group " + groupid);
			});
		});
	}).trigger('change');
}

function activate_invitation_modal(modal, form) {
	var id      = modal.attr('id');
	var email   = modal.data('email');
	var token   = modal.data('token');
	var button  = $('A[for="' + id + '"]', form);
	var groupid = $('#identifier', form).val();

	button.on('click', function(event)  {
		event.preventDefault();
		modal.show();
	});

	$('#resend_button', modal).on('click', function () {
		send_instruction(form, { email: email, token: token }, groupid, 'invite_resend', function () {
console.log('Resend accepted');
		});
	});

	$('#remove_button', modal).on('click', function () {
		send_instruction(form, { email: email, token: token }, groupid, 'invite_remove', function () {
			button.parent().parent().remove();  // remove the line with the invitation
		});
	});

	$('button', modal).on('click', function () { modal.hide() });
}

function activate_invite_add(form) {
	var button  = $('BUTTON#invite', form);
	var table   = $('TABLE#list_invitations TBODY', form);
	var groupid = $('#identifier', form).val();

	button.on('click', function () {
		event.preventDefault();
		var emails = $('TEXTAREA#invite_emails', form);
		send_instruction(form, { emails: emails.val() }, groupid, 'invite_new', function (answer) {
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

	$("form#group_list").map(function () {
		var form = $(this);
		activate_membership_change(form);
	});
})

