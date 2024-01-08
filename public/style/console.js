
var unique_counter = 42;

function add_val_message(form, input, level, message) {
	var unique = unique_counter++;
	$('LABEL[for="' + input + '"]', form).each(function() {
		$(this).parent().append('<div id="msg-' + unique + '" class="val-msg val-' + level + '">' + message + '</div>');
	});

	$('#' + input, form).on('focus', function () {
		$('#msg-' + unique).remove();
		update_form_status(form);
	});
}

function process_errors_and_warnings(form, data) {
	$('DIV.val-msg', form).remove();
	data.errors.forEach( function(error) { add_val_message(form, error.at(0), 'error', error.at(1)) });
	data.warnings.forEach(function(warn) { add_val_message(form, warn.at(0),  'warn',   warn.at(1)) });
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
               +'<legend>' + reason + '</legend><h5>' + label.html() + '</h5>' + node.html() + '</fieldset>');
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

	var save   = $('#save_button', form);
	var cancel = $('#cancel_button', form);
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
		form.addClass('changed');
	 	update_form_status(form);
	});
}

function cancel_without_saving(form) {
	var modal = $('#cancel_without_saving', form);
	$('#cancel_button', form).on('click', function (event) {
		if(form.hasClass('changed')) {
			event.preventDefault();
       		modal.show();
		}
	});

	$('#cancel_oops',    modal).on('click', function () { modal.hide() });
	$('#cancel_confirm', modal).on('click', function () { modal.hide(); form.submit() });
};

function accept_form_data(form, how) {
	var data = form.serialize();
	data.how = how;
	var action = '/dashboard/' + form.attr('id');
console.log("AJAX: " + action);
console.log(data);

	$.ajax({
		type: 'POST',
		url: action,
		data: data,
		dataType: 'json',
		success: function (response) {
			console.log('Submission was successful.');
			console.log(response);
 			process_errors_and_warnings(form, response);
			update_form_status(form);
//			if(errors==0) { form.submit(); }
		},
		error: function (response) {
			console.log('Form ' + form.attr('id') + ' delivery error: ' + response.status);
			alert('The server could not be reached: ' + response.status);  //XXX translation
			console.log(response);
		},
	});
}

function save_validated_form(form) {
	var save = $('#save_button', form);
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
			accept_form_data(form, 'save_when_ok');
		}
	});
}

function install_form(form) {
	$('[required]').each(function () {
		var p = $(this).attr('placeholder');
		$(this).attr('placeholder', p + ' (required)');   //XXX translation
	});

	create_field_versioning(form);
	cancel_without_saving(form);
	save_validated_form(form);
	accept_form_data(form, 'validate');
	monitor_form_changes(form);
};

$(document).ready(function() {
	$("form").each( function () { install_form($(this)) } );

	// make alerts closeable
	var alertList = document.querySelectorAll('.alert');
	alertList.forEach(function (alert) {
  		new bootstrap.Alert(alert)
	});

});
