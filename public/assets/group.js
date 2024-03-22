function handle_invite(form, data, groupid, how, success) {
    var action = '/dashboard/config-member/' + groupid + '?' + how;
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
			handle_invite(form, { identid: identid }, groupid, 'change_identity', function () {
console.log('change identity to ' + identid + " for group " + groupid);
			});
		});
	}).trigger('change');
}

function activate_admin_change(form) {
	//Get number of current admin in group by count fa-user-tie on row
	var adminNum = $('.member-row .fa-solid.fa-user-tie').length;

	$('.member-row').each(function() {
	  var rights = $(this).find('.rights');
  
	  $(this).click(function() {
		  var rightsInner = rights.html().trim();
		  if (rightsInner == '') {
			rights.html('<i class="fa-solid fa-user-tie" style="border: 2px solid blue;"></i>');
			adminNum++;
		  } else {
			if (adminNum == 1) {
			  oneAdminWarning();
			  return;
			} else {
			  rights.html('');
			  adminNum--;
			}
		  }
		  changedWarning();
	  });
	});
  
	function changedWarning() {
	  var changedText = $('.warning');
	  changedText.text("Changes will only be applied when you save this form");
	  changedText.removeAttr('hidden');
	  changedText.css('color', 'red');
	}
  
	function oneAdminWarning() {
	  var changedText = $('.warning');
	  changedText.text("There must be at least one admin in the group");
	  changedText.removeAttr('hidden');
	  changedText.css('color', 'red');
	}
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
		handle_invite(form, { email: email, token: token }, groupid, 'invite_resend', function () {
console.log('Resend accepted');
		});
	});

	$('#remove_button', modal).on('click', function () {
		handle_invite(form, { email: email, token: token }, groupid, 'invite_remove', function () {
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
		handle_invite(form, { emails: emails.val() }, groupid, 'invite_new', function (answer) {
			for (email of answer.added) {
				table.append('<tr><td>' + email + '</td><td>invited</td></tr>');
			}
			emails.val('');
		});
	});
}

function only_for_admins(form) {
	if($('#is_group_admin', form).val()==1) {
		activate_admin_change(form);
		activate_delete_button(form);
		activate_invite_add(form);
	} else {
		$(":input:not([role=tab])", form).prop('disabled', true);
	}
}

$(document).ready(function() {
	$("form#config-group").map(function () {
		var form = $(this);
		$(".manage_invitation", form).each(function () { activate_invitation_modal( $(this), form ) });
		only_for_admins(form);
	});

	$("form#group_list").map(function () {
		var form = $(this);
		activate_membership_change(form);
	});
})

