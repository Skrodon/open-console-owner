function verifier_status(veri, status) {
	$('.verify-success, .verify-required, .verify-waiting', veri).hide();

	if(status==='success') { $('.verify-success' ).show() }
	else
	if(status==='todo')    { $('.verify-required').show() }
	else
	if(status==='waiting') { $('.verify-waiting' ).show() }
}

function wait_for_results(form, poll, success) {
	setTimeout(function () {
		accept_form_data(form, poll.where, { "poll-token": poll.token }, function (form, response) {
console.log("WAITING");
console.log(response);
			if(response.task_ready) {
console.log("SUCCESS");
				success(response);
			} else {
				wait_for_results(form, poll, success);
			}
		});
	}, poll.delay);
}

function activate_url_check(form) {	
	var url_input   = $('INPUT#url', form);
	var check_block = $('DIV#check-url', form);

	url_input.on('change', function () {
		verifier_status(check_block, 'todo');
	}).on('focus', function () {
		verifier_status(check_block, 'todo');
	});;

	$('#check-url-button', check_block).on('click', function () {
console.log("CHECK");
		accept_form_data(form, 'check-url', undefined, function (form, response) {
console.log("SUBMIT");
console.log(response);
			var poll = response.poll;
			verifier_status(check_block, 'waiting');
			wait_for_results(form, poll, function (answer) {
console.log("SUCCESS");
console.log(answer);
				verifier_status(check_block, 'success');
			});
		});
	});
}

$(document).ready(function() {
	$("form#config-website").map(function () {
		var form = $(this);
		activate_url_check(form);
	});
})

