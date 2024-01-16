function activate_language_selector(form) {
	var table = $("#langtab", form).first();
    var uniqueLangs = {};

	// Helper make row not collapse when sort
	function fixHelperModified(event, tr) {
		var originals = tr.children();
		var helper    = tr.clone();
		helper.children().each(function(index) { $(this).width(originals.eq(index).width()) });
		return helper;
	};

	$("TBODY", table).sortable({ 
		helper: fixHelperModified,
		update: function () {
			updateHiddenInput();
		}
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
	$('#language_list option', table).each(function () {
		var langName = $(this).text();
		if(uniqueLangs[langName]) {
			$(this).remove();
		} else {
			uniqueLangs[langName] = true;
		}
	});

	function updateHiddenInput() {
        var selectedLanguages = $('td:first-child', table).map(function () {
            return $(this).text().trim();
        }).get();

        // updated hiddenInput languages list separate by comma
        var hiddenInput = $('#ordered_lang', form);
        hiddenInput.val(selectedLanguages.join(','));
    }

 	function languageIsSelected(language) {
		return $('td:first-child', table).toArray().some(function (element) {
			return $(element).text() === language;
		});
	}

	$('#language_list', form).on('change', function () {
		$(this).find('option:selected').each( function(index, selectedLanguage) {
			var lang = $(selectedLanguage).text();
			if(languageIsSelected(lang)) { return }

			var newRow = '<tr>' +
				'<td class="text-center align-middle">' + lang + '</td>' +
				'<td class="text-center"> \
					<a href="#" class="btn btn-danger remove-link" title="Remove"> \
						<i class="fa fa-times" aria-hidden="true"></i> \
					</a> \
				</td>' +
				'</tr>';
			table.append(newRow);

            updateHiddenInput();

			$('#language_list option:contains("' + lang + '")', form).prop('selected', false);	
		})
	});

	table.on('click', '.remove-link', function (event) {
		event.preventDefault();
		$(this).closest('TR').remove();

        updateHiddenInput();
	});
}

$(document).ready(function() {
	$("form#config_account").map(function () {
		var form = $(this);
		activate_language_selector(form);
	});
})

