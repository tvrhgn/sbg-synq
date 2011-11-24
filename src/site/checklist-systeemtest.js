/**
 * 
 *
var ids = [ "Algemeen", "Attribuutcontrole", "Dataextractie",
		"Datavolledigheidcontroles", "DBCinformatie", "Koppelen",
		"Pseudonimisering", "Structuurcontroles", "Uniekewaarden",
		"Vragenlijsten" ];

 */

var ids = [  
		"Algemeen", "Attribuutcontrole", "Dataextractie",
		"Datavolledigheidcontroles", "DBCinformatie", "Koppelen",
		"Pseudonimisering", "Structuurcontroles", "Uniekewaarden",
		"Vragenlijsten", "missed", "fail", "schema", "sbg-synq" ];

var kenmerken = [ "geen", "verplicht", "reeks", "normatief", "steekproef", "relatie",
		"uniek", "formaat"];


function reset() {
	$("div.test").hide();
	$("div.test-info").hide();
	$("div.test-info").addClass("off");
	$.each( ids.concat(kenmerken), function( ix, elt ) {
		$("#" + elt).addClass("off");
	});		
}

function toggle_fn(selector, name) {
	return function() {
		var owner = $(this);
		if (owner.hasClass("off")) {
			owner.removeClass("off");
			reset();
			$(selector).show();
		} else {
			owner.addClass("off");
			$(selector).hide();
		}
	};
}

function toggle_fn_and(selector, name) {
	return function() {
		var owner = $(this);
		if (owner.hasClass("off")) {
			owner.removeClass("off");
			$("div.test").not(selector).hide();
		} else {
			owner.addClass("off");
		}
	};
}

function toggle_all() {
	return function() {
		var owner = $(this);
		if ( owner.hasClass("off")) {
			owner.removeClass("off");
			owner.text("geen")
			$("div.test").show();
		} else {
			owner.addClass("off");
			owner.text("alle")
			reset();
		}
	}
}

$(document).ready(function() {
	

	$.each(kenmerken, function( ix, elt ) {
		$("#" + elt).click(toggle_fn_and("." + elt, elt));
	});
	$.each(ids, function( ix, elt ) {
		$("#" + elt).click(toggle_fn("." + elt, elt));
	});
	$("#pass").click(toggle_fn(".sbg-synq-test, .pass", "x"));
	
	$("#missed").before("<div id='show_all' class='test-control s-show-all off'>173</div>");
	
	$("#show_all").click(toggle_all());
	
});

