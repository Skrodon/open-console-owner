function activate_proof_selector(form) {
	$('INPUT#method-dns',    form).on('click', function () { $('BUTTON#website-dns-tab',    form).toggle(this.checked) });
	$('INPUT#method-inline', form).on('click', function () { $('BUTTON#website-inline-tab', form).toggle(this.checked) });
	$('INPUT#method-file',   form).on('click', function () { $('BUTTON#website-file-tab',   form).toggle(this.checked) });
}

$(document).ready(function() {
	$("form#proof-website").map(function () {
		var form = $(this);
		activate_proof_selector(form);
	});
})

