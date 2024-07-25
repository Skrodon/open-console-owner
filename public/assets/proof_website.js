
function wait_for_task(form, poll, trace, success, failed) {
	setTimeout(function () {
		accept_form_data(form, poll.where, { "task": poll.task }, function (form, answer) {
			process_errors_and_warnings(form, answer);
// console.log(answer);
			if(answer.task_ready) {
				show_trace(trace, answer.show_trace);
				if(answer.task_ready==='success') { success(answer) } else { failed(answer) }
			} else {
				wait_for_task(form, poll, trace, success, failed);
			}
		});
	}, poll.delay);
}

/*
 * Website URL verifier
 */

function verifier_status(form, status) {
	$('.verify-success, .verify-required, .verify-waiting, .verify-info, .verify-failed, .verify-step2', form).hide();

	     if(status==='success') { $('.verify-success, .verify-info, .verify-step2', form).show() }
	else if(status==='todo')    { $('.verify-required', form).show() }
	else if(status==='waiting') { $('.verify-waiting', form).show() }
	else if(status==='failed')  { $('.verify-failed, .verify-info', form).show() }
}

function activate_url_check(form) {	
	var url_input   = $('INPUT#website', form);
	var check_block = $('DIV#check-url', form);

	url_input.on('change focus', function () {
		verifier_status(form, 'todo');
	});

	$('#check-url-button', check_block).on('click', function () {
		accept_form_data(form, 'check-url', undefined, function (form, response) {
			process_errors_and_warnings(form, response);
			var poll = response.poll;
			if(poll) {
				verifier_status(form, 'waiting');
				wait_for_task(form, poll, $('TABLE#check-trace'), function (answer) {
					$('INPUT#proofid', form).val(answer.proofid);
					$('INPUT#website', form).val(answer.website);
					verifier_status(form, 'success');
				}, function (answer) {
					verifier_status(form, 'failed');
				});
			}
		});
	});
}

function activate_check_trace_modal(form) {
	var info_modal = $('#check-info-modal', form);
	$('#check-url-info', form).on('click', function(event)  {
       	event.preventDefault();
		info_modal.show();
	});
	$('BUTTON', info_modal).on('click', function () { info_modal.hide() });
}

/*
 * Starter
 */

$(document).ready(function() {
	$('form#config-website').map(function () {
		var form = $(this);
		activate_url_check(form);
		activate_check_trace_modal(form);
		activate_prooftype_buttons(form, 'website', [ 'dns', 'html', 'file' ]);
	});

})

