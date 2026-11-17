$().ready(function(){
    $('.popup').each(function (i, e) {
    	e.children[1].style.display = 'block';
    	tippy6(e.children[0], {
        	content: e.children[1],
        	interactive: true,
        	arrow: true,
        	theme: 'light-border',
        	size: 'large',
        	maxWidth: parseInt(e.children[1].dataset.size)
    	});
	});
});