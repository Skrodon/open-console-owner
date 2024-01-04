
function create_field_versioning(form) {
	var version = $('#object_version').val();
	$('DIV.history', form).each(function () {
		var node   = $(this);
		var target = node.attr('for');
		var label  = $('LABEL[for="' + target + '"]');
		if(label.length==0) {
			node.replaceWith('<div style="color: red">History of missing label: ' + target + '</div>');
		}
		else if(node.data('schema') >= version) {
			var reason = node.data('reason');
			node.replaceWith('<fieldset class="history" for="' + target + '" style="display: block">'
               +'<legend>' + reason + '</legend><h5>' + label.html() + '</h5>' + node.html() + '</fieldset>');
			label.addClass('has-changed');
		}
		else {
			node.css('display', 'none');
		}
	});
};

$(document).ready(function() {
	$("form").each( function () {
		create_field_versioning($(this)) }
	);

	// make alerts closeable
	var alertList = document.querySelectorAll('.alert');
	alertList.forEach(function (alert) {
  		new bootstrap.Alert(alert)
	});

});
