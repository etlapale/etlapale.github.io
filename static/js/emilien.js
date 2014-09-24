var locations = ["/code",
		 "/contact",
		 "/research",
		 "/welcome"];

$(document).ready(function() {

    var switchTo = function(page, saveHistory) {
	$("article").fadeTo("fast", 0.02, function() {
	    // Update the welcome class
	    if (page == "/welcome")
		$("#content").addClass("welcome");
	    else
		$("#content").removeClass("welcome");
	    // Load the new page content
	    $("article").load("/parts"+page+".html", function() {
		// Show content
		$("article").fadeTo("slow", 1.0);
		// Update webpage title
		$(document).prop('title',
				 $("article h1").text() + " - Émilien Tlapale");
	    });
	    // Save in the history
	    if (saveHistory)
		history.pushState(null, null, page);
	});
    };

    $(window).bind("popstate", function(event) {
	var loc = document.location.pathname;
	if ($.inArray(loc, locations) >= 0)
	    switchTo(loc, false);
    });

    // Create AJAX links 
    $.each(locations, function(index,value) {
	$("a[href='"+value+"']").click(function() {
	    switchTo(value, true);
	    return false;
	});
    });
});
