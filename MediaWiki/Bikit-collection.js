	var collectionList = {}, total = {}, checkWithToc = $(".bwiki-collection-toc").length > 0;

	mw.util.addCSS(`
	.bwiki-collection-checkbox.checkbox-default{
		position:relative;
	}
	.bwiki-collection-checkbox.checkbox-default > div{
		position: absolute;
		display: inline-block;
		cursor:pointer;
		width: 30px;
		height: 30px;
		top: 0;
		left: 0;
		background-image: url(data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9Im5vIj8+IDwhLS0gQ3JlYXRlZCB3aXRoIFZlY3Rvcm5hdG9yIGZvciBpT1MgKGh0dHA6Ly92ZWN0b3JuYXRvci5pby8pIC0tPjwhRE9DVFlQRSBzdmcgUFVCTElDICItLy9XM0MvL0RURCBTVkcgMS4xLy9FTiIgImh0dHA6Ly93d3cudzMub3JnL0dyYXBoaWNzL1NWRy8xLjEvRFREL3N2ZzExLmR0ZCI+CjxzdmcgaGVpZ2h0PSIxMDAlIiBzdHlsZT0iZmlsbC1ydWxlOm5vbnplcm87Y2xpcC1ydWxlOmV2ZW5vZGQ7c3Ryb2tlLWxpbmVjYXA6cm91bmQ7c3Ryb2tlLWxpbmVqb2luOnJvdW5kOyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sOnNwYWNlPSJwcmVzZXJ2ZSIgd2lkdGg9IjEwMCUiIHhtbG5zOnZlY3Rvcm5hdG9yPSJodHRwOi8vdmVjdG9ybmF0b3IuaW8iIHZlcnNpb249IjEuMSIgdmlld0JveD0iMCAwIDMwMAkzMDAiPgo8ZGVmcy8+CjxnIGlkPSLlm77lsYIgMSIgdmVjdG9ybmF0b3I6bGF5ZXJOYW1lPSLlm77lsYIgMSI+CjxwYXRoIGQ9Ik0tMC42MTI5NzYrMzAwLjI5MkwyOTkuNzY4LTAuMDg5NTYxN0wtMC42MTI5NzYrMC4zMTg1NjVMLTAuNjEyOTc2KzMwMC4yOTJaIiBvcGFjaXR5PSIxIiBmaWxsPSIjMWVlNTcxIi8+CjxwYXRoIHN0cm9rZT0iI2ZmZmZmZiIgc3Ryb2tlLXdpZHRoPSIyMi41MTU4IiBkPSJNMzYuMzA2Nis5My42OTM4TDgwLjczNTkrMTQxLjAxOUwxODAuNjYyKzM0LjUyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlLWxpbmVjYXA9ImJ1dHQiIG9wYWNpdHk9IjEiIHN0cm9rZS1saW5lam9pbj0ibWl0ZXIiLz4KPC9nPgo8L3N2Zz4K);
		background-size: cover;
		filter: grayscale(1);
		opacity: 0.5;
	}
	.bwiki-collection.checked .bwiki-collection-checkbox.checkbox-default > div{
		filter: grayscale(0);
		opacity: 1;
	}
	`)

	new mw.Api().get({
		"action": "query",
		"format": "json",
		"meta": "userinfo",
		"formatversion": "2",
		"uiprop": "options",
		// "userId": (document.cookie.match(/DedeUserID=([^;]+)/) || [])[1] || ""
	}).then(function(data){
		console.log(data.query.userinfo.options)
		$(".bwiki-collection").each(function(){
			var $item = $(this);
			var listName = $item.attr("data-collectionlist");
			var name = $item.attr("data-collection");
			if(listName === undefined || listName === "") return true;
			if(collectionList[listName] === undefined) {
				collectionList[listName] = data.query.userinfo.options["userjs-collectionList-" + listName] || "";
				total[listName] = 0;
				list = collectionList[listName] = collectionList[listName].split(",")
				if(list[0] === "") list.splice(0,1)
			}
			if(list.indexOf(name) !== -1) {
				$item.addClass("checked");
				$item.attr("data-paramc", "已获取")
				if(checkWithToc) $(".toctext").each(function(){ if($(this).text() === name) $(this).addClass("checked") })
			} else {
				$item.attr("data-paramc", "未获取")
			}
			total[listName]++;
		})

		$.each(total, function(listName, num) {
			$(".bwiki-collection-totalnum-" + listName).text(num);
			$(".bwiki-collection-checknum-" + listName).text(collectionList[listName].length);
		});

		$(".bwiki-collection-checkbox").append("<div>");

		$("body").on("click", ".bwiki-collection-checkbox div", function(){
			var $item = $(this).parents(".bwiki-collection");
			var listName = $item.attr("data-collectionlist");
			var list = collectionList[listName];
			var name = $item.attr("data-collection");
			if(list.indexOf(name) !== -1) {
				list.splice(list.indexOf(name), 1)
				$item.removeClass("checked");
				$item.attr("data-paramc", "未获取")
				if(checkWithToc) $(".toctext").each(function(){ if($(this).text() === name) $(this).removeClass("checked") })
			} else {
				list.push(name);
				$item.addClass("checked");
				$item.attr("data-paramc", "已获取")
				if(checkWithToc) $(".toctext").each(function(){ if($(this).text() === name) $(this).addClass("checked") })
			}
			$(".bwiki-collection-checknum-" + listName).text(list.length);
			changeUserOptions("userjs-collectionList-" + listName, list.join(","))
		})
	})
	

	function changeUserOptions(key, value) {
		new mw.Api().postWithToken( 'csrf', {
			"action": "options",
			"format": "json",
			"optionname": key,
			"optionvalue": value,
		} );
	}