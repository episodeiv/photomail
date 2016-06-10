$(document).foundation();

var lightboxItems = [];
var pswpElement = $('.pswp')[0];

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

var findIndexForImage = function(link) {
	var i = 0;

	var index;

	$('.lightbox').each(function() {
		if(this === link) {
			index = i;
			return false;
		}
		i++;
	});

	if(typeof(index) === 'undefined') {
		return 0;
	}
	else {
		return index;
	}
}

var showLightbox = function(source) {
	var options = {
		index: findIndexForImage(source)
	};

	var lightbox = new PhotoSwipe(pswpElement, PhotoSwipeUI_Default, lightboxItems, options);
	lightbox.init();
};

$(document).ready(function() {
	prepareLightboxImages();
});
