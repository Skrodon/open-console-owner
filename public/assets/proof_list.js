
function handle_proof_change(form, proofid, data, how, success) {
    var action = '/dashboard/' + form.attr('id') + '/' + proofid + '?' + how;

    $.ajax({
        type: 'POST',
        url: action,
        data: data,
        dataType: 'json',
        success: function (response) {
			response.notifications.forEach(function(text) { alert(text) });
            if(response.redirect) { window.location = response.redirect }

        },
        error: function (response) {
            alert('Form ' + form.attr('id') + ', the server could not be reached: ' + response.status);  //XXX translation
        },
    });
}

function remove_proof(form) {
	form.on('click', '.remove-proof', function(event) {
		event.preventDefault();
		var proofid = $(this).parent().parent().data('proof');
		handle_proof_change(form, proofid, { }, 'delete', function () {});
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
		update: function (e, ui) { reownMove($(this), e, ui) },
		cancel: 'th,tr[data-editable="false"]'  // don't move group headers
	});

	function reownMove(list, e, ui) {
		var item    = ui.item;
		var proofid = item.data('proof');
		var ownerid;

		// find owner row before new position
		var row     = item;
		while(row = row.prev('tr').first()) {
			if(row.length==0) {   // Accidentally dropped before personal header
				row = item;       // XXX does sortable() have a 'do not drop after' or a row range?
				while(row = row.next('tr').first()) {
					if(ownerid = row.data('owner')) { break }
				}
				break;
			}
			if(ownerid = row.data('owner')) { break }
		}
		if(row.data('admin') == 'false') {
			item.data('editable', 'false');
			$('I.fa-pen', item).each(function () { $(this).removeClass('fa-pen').addClass('fa-magnifying-glass') });
			$('A.remove-prove', item).remove();
		}

		handle_proof_change(form, proofid, { 'new_owner': ownerid }, 'reown', function () {} );
	};
}

function install_prooflist_form(form) {
	activate_prooflist_sorter(form);
	remove_proof(form);
}

$(document).ready(function() {
    $('form.proof-list').each( function () { install_prooflist_form($(this)) } );
})

