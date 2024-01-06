
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

function remove_val_messages(form) {
	$('DIV.val-msg', form).remove();
};

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

	var balloon = $('.save_balloon');
console.log("BALLOONS=" + balloon.length);
	$('#sum_hints',  balloon).text(sum_hints);
	$('#sum_errors', balloon).text(sum_errors);
	$('#sum_warns',  balloon).text(sum_warns);

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

function save_validate_form(form)
{	var save = $('#save_button', form);
	save.on('click', function (event) {
		var missing = 0;
		$('[required]', form).each(function () {
			if($(this).val() === '') {
				add_val_message(form, $(this).attr('id'), 'error', 'Field is required'); //XXX translation
				missing++;
			}
		});

		if(missing) {
			event.preventDefault();
			update_form_status(form);
		} else {
			// AJAX Call to do server-side validation.
			// May return errors and warnings
event.preventDefault();
		}
	});

	save.on('mouseenter', function () {
		// https://urin.github.io/jquery.balloon.js/
		$('#save_button', form).balloon({
			html: true,
			contents: $('#save_balloon', form).clone().css('display', 'block'),
			hideDuration: 1000,
			tipSize: 20,
			css: { 'font-size': '100%', 'width': '30em', 'border-radius': '1em' },
		}).show;
	});
}
// function create_save_balloon(form) {

function install_form(form) {
	$('[required]').each(function () {
		var p = $(this).attr('placeholder');
		$(this).attr('placeholder', p + ' (required)');   //XXX translation
	});
	$('[id="confirm"]').val($('[id="password"]').val());  //XXX only form 'account'

	create_field_versioning(form);
	cancel_without_saving(form);
//	create_save_balloon(form);
	save_validate_form(form);
	remove_val_messages(form);
	add_val_message(form, 'email', 'error', 'no such place');
	update_form_status(form);
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
