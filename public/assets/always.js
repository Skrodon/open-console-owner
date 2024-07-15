

$(document).ready(function() {

	// Both on logged-in and unauth pages.  Standard input-group layout
	
	$('INPUT[type="password"]').each(function () {
		var field  = $(this);
		var toggle = $( $('.eye_toggle', field.parent()) );

		toggle.on('click', function (e) {
			e.preventDefault();
			toggle.removeClass('fa-eye-slash').removeClass('fa-eye');
			if(field.attr('type') === 'password') {
				field.attr('type', 'text');
				toggle.addClass('fa-eye');
			}
			else
			{	field.attr('type', 'password');
				toggle.addClass('fa-eye-slash');
			}
		});
	});

	// Anywhere we can find select boxes which need search
	$('.search-select').select2({theme: 'bootstrap-5'});

	// make alerts closeable
	$('.alert').each(function () {
		var alert = $(this);
		$('.close', alert).on('click', function () { alert.hide() });
	});

	// enable tooltips
	$('[data-bs-toggle="tooltip"]').tooltip();

	// copy-paste text blocks
	$('PRE.copy-code').each(function () {
		var pre = $(this);
		pre.before('<i class="fa-regular fa-copy copier" aria-label="copy" for="' + pre.attr('id') + '"></i>');
	});

	$('.copier').each(function () {
		var icon = $(this);
		var code = $('PRE#' + icon.attr('for'));
		icon.on('click', function (event) {
			navigator.clipboard.writeText(code.text());
		});
	});

	// download text blocks
	$('PRE.download-code-inline').each(function () {
		var pre = $(this);
		pre.before('<i class="fa-solid fa-download downloader" aria-label="download" for="' + pre.attr('id') + '"></i>');
	});

	$('.downloader').each(function () {
		var icon = $(this);
		var code = $('PRE#' + icon.attr('for'));
		icon.on('click', function (event) {
			var node = $('<a>', {
				id: 'here',
				download: code.data('file'),
				href: 'data:' + code.data('ct') + ';base64,' + window.btoa(code.text()), // only ascii
                text: 'load' });
console.log(node);
			code.append(node);
			node.click();
console.log("clicked");
			$('#here').click();
		});
	});

});
