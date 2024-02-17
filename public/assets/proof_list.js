
function handle_proof_change(form, proofid, data, how, success) {
console.log('#1');
    var action = '/dashboard/' + form.attr('id') + '/' + proofid + '?' + how;
console.log(action);

    $.ajax({
        type: 'POST',
        url: action,
        data: data,
        dataType: 'json',
        success: function (response) {
            if(response.redirect) { window.location = response.redirect }
        },
        error: function (response) {
            alert('Form ' + form.attr('id') + ', the server could not be reached: ' + response.status);  //XXX translation
        },
    });
}

function activate_prooflist_sorter(form) {
	var table = $('#prooflisttab', form).first();

	// Helper to make row not collapse when sort
	function fixHelperModified(event, tr) {
		var originals = tr.children();
		var helper    = tr.clone();
		helper.children().each(function(index) { $(this).width(originals.eq(index).width()) });
		return helper;
	};

	$("TBODY", table).sortable({
		helper: fixHelperModified,
		update: function (e, ui) { reownMove(e, ui) },
		cancel: 'th,.not-group-admin'  // don't move group headers
	});

	function reownMove(e, ui) {
		var row     = ui.item;
		var proofid = row.data('proof');
		var ownerid;
		while(row = row.prev('tr').first()) {
			if(ownerid = row.data('owner')) { break }
		}
console.log("REOWN " + proofid + " --> " + ownerid);
		handle_proof_change(form, proofid, { 'new_owner': ownerid }, 'reown', function () {} );
console.log("DONE");
	};
}

function install_prooflist_form(form) {
	activate_prooflist_sorter(form);
}

$(document).ready(function() {
    $('form.proof-list').each( function () { install_prooflist_form($(this)) } );
})

