
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
 * Switch between proof types
 */

// On an first-step page, like website
function activate_prooftype_buttons(form, set, types) {
	types.forEach(function (kind) {
		$('BUTTON#proof-' + kind, form).on('click', function () {
       		event.preventDefault();
			window.location = '/dashboard/' + set + '/' + $('INPUT#proofid').val() + '?prover=' + kind;
		});
	});
}

function activate_prooftype_radio(form) {
	var sel = $('#proof-methods', form);
	$('INPUT[name="prover"]', sel).on('click', function () {
		var method = $(this).val();
		$('DIV.proof-page[id!="proof-page-'+method+'"]', form).hide();
		$('DIV[id="proof-page-'+method+'"]', form).show();
		$('DIV#run-proof', form).toggle(method!=='none');
	});

	var prover = $('INPUT#selected-prover', form).val();
	$('INPUT:radio[name="prover"][value="' + prover + '"]').click();
}

function prover_status(form, status) {
	$('.proof-success, .proof-waiting, .proof-info, .proof-failed', form).hide();

	     if(status==='todo')    { $('.proof-todo', form).show() }
	else if(status==='success') { $('.proof-success, .proof-info', form).show() }
	else if(status==='waiting') { $('.proof-waiting', form).show() }
	else if(status==='failed')  { $('.proof-failed, .proof-info', form).show() }
}

function activate_run_proof(form) {
	prover_status(form, 'todo');
	$('BUTTON#start-proof-button', form).on('click', function () {
       	event.preventDefault();
		accept_form_data(form, 'start-prover', undefined, function (form, response) {
			process_errors_and_warnings(form, response);
			var poll = response.poll;
			if(poll) {
				prover_status(form, 'waiting');
				wait_for_task(form, poll, $('TABLE#prover-trace'), function (answer) {
					prover_status(form, 'success');
				}, function (answer) {
					prover_status(form, 'failed');
				});
			}
		});
	});
}

function activate_proof_trace_modal(form) {
	var info_modal = $('#proof-info-modal', form);
	$('#run-proof-info, #show-proof-info', form).on('click', function(event)  {
       	event.preventDefault();
		info_modal.show();
	});
	$('BUTTON', info_modal).on('click', function () { info_modal.hide() });
}

function activate_run_show_toggle(form) {
	var create = $('DIV#proof-create', form);
	var show   = $('DIV#proof-show', form);
	var has = $('INPUT#has-proof', form).val();
	if(has==='none') { create.show(); show.hide() } else { create.hide(); show.show() }

	$('BUTTON#redo-proof', form).on('click', function () {
       	event.preventDefault();
		show.hide(); create.show();
	});
}

/*
 * Starter
 */

$(document).ready(function() {
	$('form.proof-form').map(function () {
		var form = $(this);
		activate_prooftype_radio(form);
		activate_run_proof(form);
		activate_proof_trace_modal(form);
		activate_run_show_toggle(form);
	});
})

