function verifier_status(form, status) {
	$('.verify-success, .verify-required, .verify-waiting, .verify-info, .verify-failed, .verify-step2', form).hide();

console.log("STATUS = " + status);
	if(status==='success') { $('.verify-success, .verify-info, .verify-step2', form).show() }
	else
	if(status==='todo')    { $('.verify-required', form).show() }
	else
	if(status==='waiting') { $('.verify-waiting', form).show() }
	else
	if(status==='failed') { $('.verify-failed, .verify-info', form).show() }
}

function wait_for_results(form, poll, success, failed) {
	setTimeout(function () {
		accept_form_data(form, poll.where, { "task": poll.task }, function (form, response) {
console.log(response);
			if(response.task_ready) {
				show_trace( $('TABLE#check-trace'), response.show_trace );
				if(response.task_ready==='success') {
console.log("SUCCESS");
					success(response);
					$('INPUT#proofid', form).val(response.proofid);
					$('INPUT#url', form).val(response.url);
				} else {
					failed(response);
console.log("FAILED");
				}
			} else {
console.log("WAITING");
				wait_for_results(form, poll, success, failed);
			}
		});
	}, poll.delay);
}

function activate_url_check(form) {	
	var url_input   = $('INPUT#url', form);
	var check_block = $('DIV#check-url', form);

	url_input.on('change', function () {
		verifier_status(form, 'todo');
	}).on('focus', function () {
		verifier_status(form, 'todo');
	});;

	$('#check-url-button', check_block).on('click', function () {
console.log("CHECK");
		accept_form_data(form, 'check-url', undefined, function (form, response) {
console.log("SUBMIT");
console.log(response);
			process_errors_and_warnings(form, response);
			var poll = response.poll;
			if(poll) {
				verifier_status(form, 'waiting');
				wait_for_results(form, poll, function (answer) {
					verifier_status(form, 'success');
				}, function (answer) {
					verifier_status(form, 'failed');
				});
			}
		});
	});
}

function activate_trace_modal(form) {
	var info_modal = $('#check-info-modal', form);
	$('#check-url-info', form).on('click', function(event)  {
       	event.preventDefault();
		info_modal.show();
	});
	$('BUTTON', info_modal).on('click', function () { info_modal.hide() });
}

function activate_step2(form) {
	[ 'dns', 'html', 'file' ].forEach(function (kind) {
		$('BUTTON#proof-' + kind, form).on('click', function () {
       		event.preventDefault();
			window.location = '/dashboard/website/' + $('INPUT#proofid').val() + '?prover=' + kind;
		});
	});
}

function proof_method_select(form, method) {
	$('DIV.proof-page[id!="proof-page-'+method+'"]', form).hide();
	$('DIV[id="proof-page-'+method+'"]', form).show();
}

function activate_step3(form) {
	var sel = $('#proof-methods', form);
	$('INPUT[name="prover"]', sel).on('click', function () {
		proof_method_select(form, $(this).val());
	});
}

$(document).ready(function() {
	$('form#config-website').map(function () {
		var form = $(this);
		activate_url_check(form);
		activate_trace_modal(form);
		activate_step2(form);
		activate_step3(form);

		var prover = $('INPUT#selected-prover', form).val();
		$('INPUT:radio[name="prover"][value="' + prover + '"]').click();
	});

})

