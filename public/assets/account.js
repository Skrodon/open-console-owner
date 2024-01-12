function activate_language_selector(form) {
	var table = $("#langtab", form).first();
    var uniqueLangs = {};

	table.on('click', '.remove-link', function (event) {
        event.preventDefault();
        $(this).closest('tr').remove();
    });

	// Helper make row not collapse when sort
	function fixHelperModified(event, tr) {
		var originals = tr.children();
		var helper = tr.clone();
		helper.children().each(function(index)
		{
		  $(this).width(originals.eq(index).width())
		});
		return helper;
	};

	$("#langtab tbody").sortable({
    	helper: fixHelperModified,
	}).disableSelection();

	// Remove duplicate language
	$('#langtab tbody tr').each(function () {
		var langName = $(this).find('td:first-child').text().trim();
		if (uniqueLangs[langName]) {
		  $(this).remove();
		} else {
		  uniqueLangs[langName] = true;
		}
	});

	// Loop through langtab checks if language existed when adds new language
    function isLanguageExists(language) {
		return $('#langtab td:first-child').toArray().some(function (element) {
			return $(element).text() === language;
		});
	}
	
	$('#languages').change(function () {
		var selectedLanguages = $(this).find('option:selected').map(function() {
			return $(this).text();
		}).get();

	
		if (selectedLanguages.length > 0) {
			$.each(selectedLanguages, function(index, selectedLanguage) {
				if (!isLanguageExists(selectedLanguage)) {
					var newRow = '<tr>' +
						'<td class="text-center align-middle">' + selectedLanguage + '</td>' +
						'<td class="text-center"> \
							<a href="#" class="btn btn-danger remove-link" title="Remove"> \
								<i class="fa fa-times" aria-hidden="true"></i> \
							</a> \
						</td>' +
						'</tr>';
					$('#langtab').append(newRow);

					$('#languages option:contains("' + selectedLanguage + '")').prop('selected', false);	
				}
			});
		}
	});
}

function activate_timezone_selector() {
	$('#timezone').select2();
}

$(document).ready(function() {
	$("form#config_account").map(function () {
		var form = $(this);
		activate_delete_button(form);
		activate_language_selector(form);
		activate_timezone_selector(form);
	});
})

