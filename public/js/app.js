$(document).foundation();

var lightboxItems = [];
var lightbox;

var prepareLightboxImages = function() {
	$('.lightbox').each(function() {
		var item = {};
		item.src = $(this).attr('href');
		// TODO: W/H
		item.w = 600;
		item.h = 600;

		lightboxItems.push(item);

		$(this).click(function(event) {
			event.preventDefault();
			showLightbox(this);
		});
	});
};

var showLightbox = function(source) {
	// TODO: start at right index
	lightbox.init();
};

$(document).ready(function() {
	prepareLightboxImages();
	console.dir(lightboxItems);

	var options = {
		index: 0
	};

	var pswpElement = $('.pswp')[0];
	lightbox = new PhotoSwipe(pswpElement, PhotoSwipeUI_Default, lightboxItems, options);
});
