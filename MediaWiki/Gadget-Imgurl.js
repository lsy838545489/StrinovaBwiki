/* 模板:外链图片 */
$(".imgurl").each(function(){
	$(this).html('<img src="'+$(this).text()+'" />');
});
$("head").append("<style>.imgurl {display: inline-block;}.imgurl img {width: inherit;height: inherit;padding: 0px;transition: all .2s ease-in-out;max-width:100%;}</style>");