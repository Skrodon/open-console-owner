
function activate_invitation_modal(modal, form) {
	var id = modal.attr('id');

	$('A[for="' + id + '"]', form).on('click', function(event)  {
		event.preventDefault();
		modal.show();
	});

	$('#resend_button', modal).on('click', function () {
	});

	$('#remove_button', modal).on('click', function () {
	});

	$('button', modal).on('click', function () { modal.hide() });
}

$(document).ready(function() {
	$("form#config_group").map(function () {
		var form = $(this);
		$(".manage_invitation", form).each(function () { activate_invitation_modal( $(this), form ) });
		activate_delete_button(form);
	});
})

