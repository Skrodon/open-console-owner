// This JavaScript is loaded for every single page.
// Most common logic is in config_form.js, which applies only to forms
// for users which are logged-in.

function password_visibility_toggle() {
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
}

function set_selections() {
	$('DIV[data-radio]').each(function () {
		var div = $(this);
		$('[name="' + div.data('radio') + '"]', div).val([div.data('pick')]);
	});

	$('DIV[data-checkbox]').each(function () {
		var div = $(this);
		$('[name="' + div.data('checkbox') + '"]', div).val([div.data('pick').split(",")]);
	});
}

// https://select2.org
function enable_select2_selectors() {
	// Anywhere we can find select boxes which need search
	$('SELECT').each(function () {
        var sel  = $(this);
		var need = sel.data('need');
        sel.val(sel.data('pick'));
		sel.select2({
			theme: 'bootstrap-5',
            minimumResultsForSearch: 20,
            allowClear: need != 'required',
		});
	});
}

function enable_bootstrap_alerts() {
	$('.alert').each(function () {
		var alert = $(this);
		$('.close', alert).on('click', function () { alert.hide() }); // make alerts closeable
	});
}

function enable_bootstrap_tooltips() {
	$('[data-bs-toggle="tooltip"]').tooltip();
}

function provide_copy_code() {
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
}

function provide_download_code() {
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
			code.append(node);
			node.click();
			$('#here').click();
		});
	});
}

$(document).ready(function() {
	password_visibility_toggle();
	enable_select2_selectors();
	set_selections();
	enable_bootstrap_alerts();
	enable_bootstrap_tooltips();
	provide_copy_code();
	provide_download_code();
});
