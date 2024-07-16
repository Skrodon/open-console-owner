
var unique_counter = 42;

function activate_delete_button(form) {
	const deleteModal   = $('#delete_confirmation_modal', form);

	$('#delete-button', form).on('click', function(event)  {
		event.preventDefault();
		deleteModal.show();
	});

	$('#cancel-delete-button', deleteModal).on('click', function () {
		deleteModal.hide();
	});

	$('#confirm-delete-button', deleteModal).on('click', function () {
		deleteModal.hide();
		accept_form_data(form, 'delete');
	});
}

function add_val_message(form, input, level, message) {
	var unique = unique_counter++;
console.log("VALMSG " + input + ", level " + level + ", " + message);
	$('LABEL[for="' + input + '"]', form).each(function() {
		$(this).parent().append('<div id="msg-' + unique + '" class="val-msg val-' + level + '">'
			+ jQuery('<div />').text(message).html() + '</div>');
	});

	$('#' + input, form).on('focus', function () {
		$('#msg-' + unique).remove();
		update_form_status(form);
	});
}

function process_errors_and_warnings(form, answer) {
	$('DIV.val-msg', form).remove(); 
	answer.errors.forEach( function(error) { add_val_message(form, error.at(0), 'error', error.at(1)) });
	answer.warnings.forEach(function(warn) { add_val_message(form, warn.at(0),  'warn',   warn.at(1)) });
	answer.notifications.forEach(function(text) { alert(text) });
}

function create_field_versioning(form) {
	var version = $('#object_version', form).val();
	$('DIV.history', form).each(function () {
		var node   = $(this);
		var target = node.attr('for');
		var label  = $('LABEL[for="' + target + '"]', form);
		if(label.length==0) {
			node.replaceWith('<div style="color: red">History of missing label: ' + target + '</div>');
		}
		else if(node.data('schema') >= version) {
			var reason = node.data('reason');
			node.replaceWith('<fieldset class="history" for="' + target + '" style="display: block">'
			+ '<legend>' + reason + '</legend><h5>' + label.html() + '</h5>' + node.html() + '</fieldset>');
			label.addClass('has-changed');
		}
		else {
			node.css('display', 'none');
		}
	});
};

function update_form_status(form) {
	var sum_hints = 0, sum_errors = 0, sum_warns = 0;
	$('DIV[role="tablist"] BUTTON.nav-link', form).each(function () {
		var tab    = $(this);
		var pane   = $('DIV[role="tabpanel"]' + tab.data('bs-target'), form).first();

		var hints  = $('FIELDSET.history', pane).length;
		if(hints)
		     { $(".show_hints",  tab).text(hints).css('display', 'inline-block') }
		else { $(".show_hints",  tab).css('display', 'none') }
		sum_hints  += hints;

		var errors = $('DIV.val-error', pane).length;
		if(errors)
		     { $(".show_errors", tab).text(errors).css('display', 'inline-block') }
		else { $(".show_errors", tab).css('display', 'none') }
		sum_errors += errors;

		var warns  = $('DIV.val-warn',  pane).length;
		if(warns)
		     { $(".show_warns",  tab).text(warns).css('display', 'inline-block') }
		else { $(".show_warns",  tab).css('display', 'none') }
		sum_warns  += warns;
	})

	var save   = $('#save-button', form);
	var cancel = $('#cancel-button', form);
	save.removeClass('bg-danger').removeClass('bg-success');

	var history = $('#form-summary', form);
	$('#sum_hints',  history).text(sum_hints);
	$('#sum_errors', history).text(sum_errors);
	$('#sum_warns',  history).text(sum_warns);

	if(sum_errors) { save.addClass('bg-danger') }
	else if(form.hasClass('changed') || sum_hints) {
		save.addClass('bg-success');
		cancel.removeClass('bg-success');
	}
};

function monitor_form_changes(form) {
	$('input, textarea, select', form).on('change', function () {
		if($(this).attr('id') !== 'password') {
			// Browser changes password, gladly we trigger on confirm
console.log("Changed by " + $(this).attr('id'));
			form.addClass('changed');
	 		update_form_status(form);
		}
	});
}

function cancel_without_saving(form) {
	var modal = $('#cancel-without-saving', form);
	$('#cancel-button', form).on('click', function (event) {
		event.preventDefault();
		if(form.hasClass('changed')) {
			modal.show();
		}
		else {	
			window.location.href = '/dashboard/';
		}
		false;
	});

	$('#cancel-oops',    modal).on('click', function () { modal.hide() });
	$('#cancel-confirm', modal).on('click', function () { modal.hide(); window.location.href = '/dashboard/' });
};

function accept_form_data(form, how, param, success) {
	var data   = form.serialize();
	if(param) { data += '&' + $.param(param) }

	var action = '/dashboard/' + form.attr('id') + '/' + $('#identifier', form).val() + '?' + how;

	$.ajax({
		type: 'POST',
		url: action,
		data: data,
		dataType: 'json',
		success: function (response) {
 			process_errors_and_warnings(form, response);
			update_form_status(form);
			if(success) { success(form, response) }
			if(response.redirect) { window.location = response.redirect }
		},
		error: function (response) {
			alert('Form ' + form.attr('id') + ', the server could not be reached: ' + response.status);  //XXX translation
		},
	});
}

function save_validated_form(form) {
	var save = $('#save-button', form);
	save.on('click', function (event) {
		event.preventDefault();

		var missing = 0;
		$('[required]', form).each(function () {
			if($(this).val() === '') {
				add_val_message(form, $(this).attr('id'), 'error', 'Field is required'); //XXX translation
				missing++;
			}
		});

		if(missing) {
			// missing before real validation, to have less work on the server
			update_form_status(form);
		} else {
			accept_form_data(form, 'save', undefined, function () {
			});
		}
	});
}

function show_trace(table, trace) {
	$('TR.trace', table).remove();
	trace.forEach((line) => {
		table.last().append($('<tr>').attr('class', 'trace')
          .append($('<td>').text(line[0]))
          .append($('<td>').text(line[1])));
	});
}

function install_config_form(form) {
	$('[required]').each(function () {
		var p = $(this).attr('placeholder');
		$(this).attr('placeholder', p + ' (required)');   //XXX translation
	});

	activate_delete_button(form);
	create_field_versioning(form);
	cancel_without_saving(form);
	save_validated_form(form);
	accept_form_data(form, 'validate');
	monitor_form_changes(form);
};

$(document).ready(function() {
	$('form.config-form').each( function () { install_config_form($(this)) } );
});
