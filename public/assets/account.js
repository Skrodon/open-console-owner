function activate_language_selector(form) {
	var table = $("#langtab", form).first();
    var uniqueLangs = {};

	$('.remove-link', table).on('click', function (event) {
		event.preventDefault();
		$(this).closest('tr').remove();
	});

	// Helper make row not collapse when sort
	function fixHelperModified(event, tr) {
		var $originals = tr.children();
		var $helper = tr.clone();
		$helper.children().each(function(index)
		{
		  $(this).width($originals.eq(index).width())
		});
		return $helper;
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

