function activate_language_selector(form) {
	var table = $("TABLE#langtab", form).first();

	// Helper to make row not collapse when sort
	function fixHelperModified(event, tr) {
		var originals = tr.children();
		var helper    = tr.clone();
		helper.children().each(function(index) { $(this).width(originals.eq(index).width()) });
		return helper;
	};

	$("TBODY", table).sortable({
		helper: fixHelperModified,
		update: function () { saveLangOrder() }
	}).disableSelection();

	// Remove duplicate language get from server in table
	var uniqueLangs = { };
	$('TBODY TR', table).each(function () {
		var langName = $(this).find('td:first-child').text().trim();
		if(uniqueLangs[langName]) {
			$(this).remove();
		} else {
			uniqueLangs[langName] = true;
		}
	});

	// Remove duplicate language get from server in languages list
	$('SELECT#languages OPTION', table).each(function () {
		var langName = $(this).text();
		if(uniqueLangs[langName]) {
			$(this).remove();
		} else {
			uniqueLangs[langName] = true;
		}
	});

	function saveLangOrder() {
		var selectedLanguages = $('td:first-child', table).map(function () { return $(this).data('code') }).get();
		$('INPUT#ordered-lang', form).val(selectedLanguages.join(','));
	}

 	function languageIsSelected(language) {
		return $('TD:first-child', table).toArray().some(function (element) {
			return $(element).text() === language;
		});
	}

	$('SELECT#language-list', form).on('change', function () {
		var list = $(this);
		list.find('OPTION:selected').each( function(index, selectedLanguage) {
			var lang = $(selectedLanguage).text();
			var code = $(selectedLanguage).val();
			if(code == '' || languageIsSelected(lang)) { return }

			var newRow = '<tr>' +
				'<td class="text-center align-middle" data-code="' + code + '">' + lang + '</td>' +
				'<td class="text-center"> \
					<a href="#" class="btn btn-danger remove-link" title="Remove"> \
						<i class="fa fa-times" aria-hidden="true"></i> \
					</a> \
				</td>' +
				'</tr>';
			table.append(newRow);
			saveLangOrder();

			/* Should work :-( */
			list.val('');
			list.trigger('change');
		})
	});

	table.on('click', '.remove-link', function (event) {
		event.preventDefault();
		$(this).closest('TR').remove();
		saveLangOrder();
	});
}

$(document).ready(function() {
	$("form#config-account").map(function () {
		var form = $(this);
		activate_language_selector(form);
	});
})

