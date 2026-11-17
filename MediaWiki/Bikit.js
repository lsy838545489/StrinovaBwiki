/*** https://wiki.biligame.com/tools/MediaWiki:Bikit.js
在原Bikit基础上进行了删改，移除了部分功能  ***/
if(typeof Bikit === "undefined") var Bikit = {};
Bikit = Object.assign(Bikit, {
    ver: 'v0.2.23',
    userId: (document.cookie.match(/DedeUserID=([^;]+)/) || [])[1] || "",
    init: function () {
        var self = this;
        // self.ready(function () {
        (window.RLQ = window.RLQ || []).push(['jquery', () => {
            self.isReady = true;
            if (self.beforeParse) self.beforeParse();
            self.extend();
            self.fixing();
            self.cating();
            self.libing();
            self.parser();
            if (self.afterReady) self.afterReady();
		}]);
    },
    ready: function (callback) {
        if (typeof $ !== 'undefined' &&
            ($('#bodyContent').length > 0 ^ (typeof mw === 'undefined' || typeof mw.Api === 'undefined' )) &&
            ((mw && (["edit", "submit"].indexOf(mw.config.get("wgAction").toLowerCase()) !== -1)) ^ $("#wikiEditor-ui-toolbar").length === 0))
            return $(function () { callback() });
        setTimeout(function () { Bikit.ready(callback) }, 5);
    },
    extend: function () {
		var $loginUser = $(".bili-game-header-user-login");
		window.thisUser = {};
		if($loginUser.length > 0 ) {
			window.thisUser = {
				id: $loginUser.children("a").attr("href").split("/").pop(),
				name: $(".bili-game-header-user-name").text(),
				icon: $loginUser.find("img").attr("src")
			}
		}
        $.fn.changeTag = function (newTag) {
            var attrs = {};
            $.each(this[0].attributes, function (idx, attr) {
                attrs[attr.nodeName] = attr.nodeValue;
            });
            this.replaceWith(function () {
                return $('<' + newTag + '/>', attrs).append($(this).contents());
            });
            return this;
        };
        Date.prototype.Format = function (fmt) { //author: meizz
            var o = {
                "M+": this.getMonth() + 1, //月份
                "d+": this.getDate(), //日
                "h+": this.getHours(), //小时
                "m+": this.getMinutes(), //分
                "s+": this.getSeconds(), //秒
                "q+": Math.floor((this.getMonth() + 3) / 3), //季度
                "S": this.getMilliseconds() //毫秒
            };
            if (/(y+)/.test(fmt)) fmt = fmt.replace(RegExp.$1, (this.getFullYear() + "").substr(4 - RegExp.$1.length));
            for (var k in o)
                if (new RegExp("(" + k + ")").test(fmt)) fmt = fmt.replace(RegExp.$1, (RegExp.$1.length == 1) ? (o[k]) : (("00" + o[k]).substr(("" + o[k]).length)));
            return fmt;
        };
    },
    parser: function () {
        var self = this;
        $('[class*="bikit-"]').each(function () {
            var cls = $(this).attr('class').split(' '), kit;
            cls = $.map(cls, function (v) {
                if (v.indexOf('bikit-') === -1) return v;
                kit ? '' : kit = v.replace('bikit-', '');
                return null;
            });
            $(this).attr('class', cls.join(' '));
            self.kiting(this, kit);
        });
    },
    loader: function () {
        var opts = {src: arguments[0]};
        if (arguments.length === 1) {
            $.type(arguments[0]) === 'object' ? opts = arguments[0] : '';
        } else {
            opts.mime = arguments[1];
        }
        this.kits.loader.main(null, opts);
    },
    data: {},
    kits: {},
    kiting: function (ele, kit) {
        try {
            var opts = $(ele).data();
            if (opts.options) {
                /* jslint evil: true */
                opts = $.extend({}, opts, (new Function('return ' + '{' + opts.options + '}'))());
                delete opts.options;
                $(ele).removeAttr("data-options");
            }
            if(this.kits[kit]) this.kits[kit].main(ele, opts);
        } catch (e) {
            console.log(e);
        }
    },
    cats: {
    	"左侧目录": "leftToc"
    },
    cating: function () {
    	var self = this;
    	$.each(mw.config.get("wgCategories"), function(i, c) {
    		var cat = self.cats[c];
    		if(!cat) return true;
    		if(typeof self.cats[cat] === "function") 
    			return self.cats[cat]();
    	});
    },
    fixs: {},
    fixing: function () {
        var fixs = "";
        $.each(this.fixs, function (k, v) { fixs += v(); });
        $("head").append(fixs);
    },
    libs: {},
    libing: function () {
        $.each(this.libs, function (k, v) { 
        	if($(".bikit-" + k).length > 0) v();
        	if($(".bwiki-" + k).length > 0) v();
        });
    },
    util: {
    	getParams(url) {
		    /*获取url的参数*/
		    url = url || decodeURI(window.location.href);
		    try {
		        var index = url.indexOf('?');
		        url = url.match(/\?([^#]+)/)[1];
		        var obj = {}, arr = url.split('&');
		        for (var i = 0; i < arr.length; i++) {
		            var subArr = arr[i].split('=');
		            obj[subArr[0]] = subArr[1];
		        }
		        return obj;
		    } catch (err) {
		        return null;
		    }
		},
    	getQueryParam: function(key){
			var params = window.location.search.substring(1).split("&");
			for (var i=0; i < params.length; i++) {
				var pair = params[i].split("=");
				if(pair[0] == key) return pair[1];
			}
			return false;
		}
    }
})

Bikit.kits.global = {
    main: function (ele, opts) {
        if (opts.home) {
            var $mli1 = $(".wiki-menu-li-1:first-child > .menu-title");
            if ($.trim($mli1.text()) === "首页") $mli1.attr("href", mw.config.get('wgScriptPath'));
        }
    }
};

Bikit.kits.apiparse = {
    main: function (ele, opts) {
        new mw.Api().get({	
		    "action": "parse",
			"format": "json",
			"text": $(ele).text(),
			"contentmodel": "wikitext"
		}).then(function(data){
			console.log(data.parse.text["*"])
			$(ele).html(data.parse.text["*"])
		})
    }
};

Bikit.kits.img = {
    main: function (ele, opts) {
        $(ele).attr("src", opts.src).addClass("bikited-img").changeTag("img");
    }
};

Bikit.kits.user = {
    main: function (ele, opts) {
        if (opts.key === "id") return $(ele).html(thisUser.id || "");
        if (opts.key === "name" && thisUser.name) return $(ele).html(thisUser.name);
        if (opts.key === "icon") return $(ele).html($("<img>").attr("src", thisUser.icon || "https://i0.hdslb.com/bfs/face/member/noface.jpg"));
    }
};

Bikit.kits.snapshot = {
    main: function (ele, opts) {
        if (opts.site === undefined ||
            ['b', 'bili', 'bilibili', 'b站', '哔哩哔哩'].indexOf(opts.site.toLowerCase()) !== -1)
            return this.bilibili(ele, opts);
    },
    bilibili: function (ele, opts) {
        var mobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ? 'mobile/' : 'cv';
        var url = 'https://www.bilibili.com/read/' + mobile + opts.id;
        var imgClickEvent = function ($, opts) {
            if (opts.width) $.find('.article-holder').css('max-width', opts.width);
            if (opts.center) $.find('.article-holder').css('margin', '0 auto');
            $.find('.article-holder .video-card').css('cursor', 'pointer');
            $.find('a').attr('target', '_blank');
            $.find('figure + p').remove();
            $.on('click', '.article-holder .video-card', function (e) {
                var aid = this.getAttribute('aid').split(',');
                aid = (aid.length === 1 || e.offsetX <= this.width / 2) ? aid[0] : aid[1];
                return window.open('https://www.bilibili.com/av' + aid);
            });
        };
        $.get(url, function (result) {
            var $iframe = $('<iframe src="about:blank" frameborder="0" width="100%" height="100px"></iframe>').css("visibility", "hidden");
            $(ele).replaceWith($iframe);
            $iframe.contents().find('body').append('<link rel="stylesheet" href="//s1.hdslb.com/bfs/static/jinkela/article/pcDetail.161b5db1b2dd75a7a380a5533371e6207d4304d0.css">' +
                $(result).find('.article-content').prop('outerHTML').replace(/data-src/g, 'src') +
                '<script>var imgClickEvent = ' + imgClickEvent.toString() + '</script>');
            $iframe[0].contentWindow.window.imgClickEvent($iframe.contents().find('body'), opts);
            $iframe.height($iframe[0].contentWindow.document.documentElement.scrollHeight);
            $iframe.css("visibility", "visible");
        });
    }
};

Bikit.kits.api = {
    /* 需要解决重复请求的问题 */
    async: true,
    url: {
        video: '//api.bilibili.com/x/web-interface/view',
    },
    main: function (ele, opts) {
        if (opts.api.toLowerCase() === 'video') return this.video(ele, opts);
    },
    video: function (ele, opts) {
        if ((opts.aid || '') + (opts.bvid || '') === '')
            throw Error('缺失视频ID，请补充 aid 或 bvid！');
        var id = opts.aid ? opts.aid = opts.aid.toString().replace('av', '') : opts.bvid
        var callback = function (data) {
            if (data.hasOwnProperty('data')) data = data.data;
            if (data.hasOwnProperty('code') && data.code === -400)
                throw Error(data.message);
            Bikit.data.video[data.aid] = data;
            Bikit.data.video[data.bvid] = data;
            var output = opts.output.toLowerCase()
            if (['pic', 'img', 'image', '图片', '封面'].indexOf(output) !== -1) {
                $(ele).append($('<img>').attr({src: data.pic}).css({
                    width: '100%',
                    height: 'auto'
                })).removeClass('bikit-api');
            } else if (['title'].indexOf(output) !== -1) {
                $(ele).text(data.title)
            } else if (['desc'].indexOf(output) !== -1) {
                $(ele).text(data.desc)
            }
        }
        if (!Bikit.data.video) Bikit.data.video = {}
        if (Bikit.data.video.hasOwnProperty(id)) return callback(Bikit.data.video[id]);
        $.get(this.url.video + (opts.aid ? '?aid=' : 'bvid=') + id, callback)
    }
};

Bikit.fixs.userRightsLink = function () {
    /* 补充右上角用户权限页链接 */
	$(".bili-game-header-user-popper ul").append(`
	<a href="/${mw.config.get("wgGameName")}/特殊:用户权限/${Bikit.userId}" style="cursor: pointer;">
		<li class="bili-game-header-user-item">
			<div class="bili-game-header-user-item-name">
				<span style="width: 60px; height: 16px; margin-right: 10px; background: url(${$(".pic-logo").attr("src")}) no-repeat; background-size: contain; ">
				</span>
				<span>本站权限</span>
			</div>
			<div><span class="iconfontH iconic_pc_arrow_right_light"></span></div>
		</li>
	</a>`)
    return "";
}

Bikit.fixs.pageInfoBtn = function () {
    /* 补充WIKI功能下拉菜单中的页面信息按钮 */
    $("#p-cactions ul.menu").append(
    	$("<li>").append($("<a></a>", {
    	href: mw.config.get("wgCookiePath") + encodeURI(mw.config.get("wgPageName")) + "?action=info",
    	ref: "info"
    }).text("页面信息")));
    return "";
}

Bikit.fixs.downloadImageBtn = function () {
    /* 补充WIKI功能下拉菜单中的页面内图片下载链接按钮 */
    if(!mw.config.get("wgUserGroups").some(g => ["sysop", "automoderated"].includes(g))) return false;
    $("#p-cactions ul.menu").append(
    	$("<li>").append($("<a></a>", {
    	href: "javascript: void(0)",
    	ref: "downloadImage"
    }).text("下载文件").click(function () {
    	var imgUrls = $("#mw-content-text img").map(function(i, img){return window.location.origin + "/" + mw.config.get("wgGameName") + "/special:redirect/file/" + img.getAttribute("alt")})
    	imgUrls = Array.from(new Set(imgUrls));
    	$("#mw-content-text").prepend(
    		$("<div>").html("点击复制后，到迅雷添加批量下载任务，超过1000个文件后需手动分批下载。<br>注：修改文件备注会导致下载异常！"),
    		$("<div>", {"class": "bwiki-copy"}).html(imgUrls.join("<br>")))
    })));
    return "";
}

Bikit.fixs.fileURL = function () {
    /* 补充WIKI文件页面的原始文件链接展示 */
    var downloadFile = function(url, filename){
		fetch(url)
	        .then(response => response.blob())
	        .then(blob => {
	            var a = document.createElement('a');
	            a.download = filename;
	            a.href = window.URL.createObjectURL(blob);
	            document.body.appendChild(a); // for firefox
	            a.click();    
	            a.remove();         
	        });
    }
    if(mw.config.get("wgCanonicalNamespace").toLowerCase() !== "file" || $("#file").length === 0) return "";
    var url = $("#file a").attr("href"), filename = $(".fullMedia a").eq(0).attr("title");
    var downloadButton = $("<a>", {href:"javascript:void(0)"})
    	.append('下载 <i class="glyphicon glyphicon-download-alt"></i>')
    	.click(function(){downloadFile(url, filename)} );
    $(".fullMedia > p").after($("<p>").append("引用地址 （<span class='bwiki-copy'>" + url + "</span>）", downloadButton))
    return "";
}

Bikit.fixs.ignoreUploadWarnings = function () {
    /* 补充WIKI编辑页面批量上传忽略警告按钮 */
    if($("#msupload-bottom").length === 0) return "";
    $("<a>").html("忽略所有警告").click(function(){$(".file-warning [type='checkbox']:not(:checked)").click()}).appendTo($("#msupload-bottom"))
	$("<a>").html("跳过警告项").click(function(){$(".file-warning [type='checkbox']:checked").click()}).appendTo($("#msupload-bottom"))
    return "";
}

Bikit.fixs.purgeCategory = function () {
    /* 分类页面批量刷新按钮 */
    if(mw.config.get("wgCanonicalNamespace") === "Category") {
		window.purge = function(){
			window.titleArray = titles.replace(", ", ",").split(",")
			window.pageIndex = 0
			new mw.Api().post({
				"action": "purge",
				"format": "json",
				"titles": titleArray.join("|")
			}).then( getPage )
		}
		window.getPage = function(){
			if(pageIndex >= titleArray.length) return alert("刷新完毕")
			$.get(mw.config.get("wgScript") + "?title="+ titleArray[pageIndex++])
			setTimeout(getPage, 500)
		}
		window.titles = [];
		$(".mw-category a").each(function(){titles.push($(this).attr("title"))})
		titles = titles.join(",")
		$("#mw-pages > p").eq(0).after("<button onclick='purge()'>批量刷新</button>")
    }
    return "";
}

Bikit.fixs.scroll = function () {
    /* 补充scroll滚动偏差修正的样式 */
    return "<style>@media (min-width: 768px) { html{scroll-padding-top: 60px;} }</style>";
}

Bikit.fixs.downloadImage = function () {
    /* 补充scroll滚动偏差修正的样式 */
    if(mw.config.get("wgUserGroups").indexOf("sysop") === -1) return "";
    if(mw.config.get("wgCanonicalSpecialPageName") !== "Listfiles") return "";
    
    var imageLinks = [];
	$(".TablePager_col_img_name a:first-child").each(function(){
	    imageLinks.push(window.location.origin + mw.config.values.wgScriptPath + "/special:redirect/file/" + $(this).text())
	})
	console.log(imageLinks.join("\n"))
	console.log("先把limit调高，如调到1000，然后复制上方的链接到迅雷批量下载，调整迅雷同时下载文件数量，建议10，后等待下载")
    return "";
}

Bikit.fixs.notify = function () {
    /* 补充notify的样式 */
    return "<style>.mw-notification.mw-notification-type-success{border-color: #6dd424;background-color: #f8fff8;color: green;}</style>";
}

Bikit.fixs.search = function () {
    /* 补充搜索范围选项 */
    if(!$("body").hasClass("mw-special-Search")) return "";
	// 搜索帮助 https://zh.moegirl.org.cn/index.php?curid=143634
	var dropdownOptions = [{label: '内容', data: ""}, {label: '标题', data: "intitle:"}, {label: '源码', data: "insource:"}],
	    dropdownInput = new OO.ui.DropdownInputWidget({options: dropdownOptions}),
	    searchInput = $("#searchText input").css("cssText", "padding-left:30px!important"),
	    selectedOptions = searchInput.val().match(/^insource:|^intitle:/g);
	dropdownInput.$element.width(64).css("display", "table-cell");
	dropdownInput.$element.find(".oo-ui-indicator-down").css("right", "0.45em");
	dropdownInput.$element.find("button").attr("style", "padding-right:1.2em; padding-left:0.6em;border-right: 0;border-radius: 2px 0 0 2px;");
	dropdownInput.on("change", function (val) { searchInput.val(val + searchInput.val().replace(/^insource:|^intitle:/g, ""))})
	if (selectedOptions !== null) dropdownInput.setValue(selectedOptions[0])
	$('#mw-search-top-table .oo-ui-fieldLayout-field').prepend(dropdownInput.$element);
    return "";
}

Bikit.fixs.versionPageLink= function () {
	// 为特殊:版本页面的扩展标签和解析函数加入tools对应页面的跳转链接
	if(mw.config.get("wgCanonicalSpecialPageName") !== "Version") return false;
    // extensiontags
    mw.util.addCSS("bdi{display:inline-block}");
    $("#mw-version-parser-extensiontags").nextAll("bdi").each(function(){
    	var link = $("<a>", {href:"/tools/帮助:解析器扩展标签#" + $(this).text().replace(/<|>/g, ""), target:"_blank"});
    	$(this).html(link.text($(this).text()))
    })

    // parserFunctions
    var parserFunctions = $("#mw-version-parser-function-hooks")[0].nextSibling.textContent
    parserFunctions = parserFunctions.replace("和", "").split("、")
    parserFunctions = parserFunctions.map(function(func){
    	return $("<a>", {href:"/tools/帮助:解析函数#" + func, target:"_blank"}).text(func)[0].outerHTML
    })
    $("#mw-version-parser-function-hooks")[0].nextSibling.remove();
    $("#mw-version-parser-function-hooks").after(parserFunctions.join("、"));
    return "";
}

Bikit.fixs.editHint= function () {
	// 为源代码编辑器补充编辑提示气泡
	(window.RLQ = window.RLQ || []).push([["jquery", "smw.tippy"], () => {
		if(mw.config.get("wgAction") !== "edit" && mw.config.get("wgAction") !== "submit") return false;
        if($( "#wikiEditor-section-main" ).length === 0) return false;
         
        var editHintFlag = mw.user.options.get("userjs-editHint") === "true";
        var editHintEvent = function(event){
            var key = $(this).text().trim().replace("#", "");
            if(event.type == "mouseover"){
                fetch("/tools/" + key).then((res)=>{ return res.text() }).then((res)=>{
                    window.editHintInstance = tippy6(this, {
                        content: $(res).find(".wiki-bot").text().trim().replace(/\n/g, "<br>") + "<div style='text-align:center'><a style='color:white' href='/tools/" + key + "' target='_blank'>→</a></div>",
                        interactive: true,
                        appendTo: () => document.body,
                        allowHTML: true,
                    });
                    window.editHintInstance.show();
                })
            } else if(event.type == "mouseout"){
                window.editHintInstance.destroy();
            }
        }

        var editHintToggleButton = new OO.ui.ToggleButtonWidget( {
            framed: false,
            classes: ['tool'],
            title: "编辑提示（测试中）" ,
            icon: "lightbulb"
        } )

        var switchEditHint = function(flag) {
            editHintToggleButton.$icon.toggleClass('oo-ui-image-progressive', editHintFlag);
            $("body")[editHintFlag?"on":"off"]("mouseover mouseout", ".cm-mw-parserfunction-name", editHintEvent)
        }

        $( "#wikiEditor-section-main" ).append($('<div class="group group-editHint" rel="editHint"></div>').append( editHintToggleButton.$element ) );

        editHintToggleButton.on('change', function() {
            editHintFlag = editHintToggleButton.active = editHintToggleButton.getValue();
            setTimeout(switchEditHint, 1)
        });

        switchEditHint()

	}]);
    return "";
}

Bikit.libs.autoset = function () {
	$(".bikit-autoset").removeClass("bikit-autoset").addClass("bikited-autoset");
	$(".bikited-autoset").each(function () {
		var opts = $(this).data(), $eles = $(opts.selector);
		delete opts.selector;
		$eles.each(function() { $(this).addClass(opts.class); })
		delete opts.class;
		$.each(opts, function(name, value) { $eles.attr(name.replace(/^data/, "data-"), value); })
	});
}

Bikit.fixs.copy = function () {
	$(".bikit-copy").removeClass("bikit-copy").addClass("bikited-copy");
	$("body").on("click", ".bikited-copy, .bwiki-copy", function () {
		window.getSelection().selectAllChildren(this);
		document.execCommand("Copy");
		// A PopupWidget.
		if(!OO.ui || window.innerWidth < 600) return window.alert("复制成功！");
		var popup = new OO.ui.PopupWidget( {
		    $content: $( '<p style="color:green">复制成功！</p>' ),
		    width: "auto",
		    padded: true
		} );
		$(this).before(popup.$element);
		popup.toggle( true );
		setTimeout(function(){popup.$element.remove();}, 2000)
		// mw.notify("复制成功，可直接粘贴", {type: "Success", tag: "copy"});
	});
}

Bikit.libs.collection= function () {
	var collectionList = {}, total = {}, checkWithToc = $(".bwiki-collection-toc").length > 0, tempList = [];

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
		filter: initial;
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
				collectionList[listName] = collectionList[listName].split(",")
			}
			tempList = collectionList[listName]
			if(tempList[0] === "") tempList.splice(0,1)
			if(tempList.indexOf(name) !== -1) {
				$item.addClass("checked");
				$item.attr("data-paramc", "已获取")
				if(checkWithToc) $(".toctext").each(function(){ if($(this).text() === name) $(this).addClass("checked") })
			} else {
				$item.attr("data-paramc", "未获取")
			}
			total[listName]++;
			
			if(window.afterCollectionItemClick) window.afterCollectionItemClick(listName)
		})
		

		$.each(total, function(listName, num) {
			$(".bwiki-collection-totalnum-" + listName).text(num);
			$(".bwiki-collection-checknum-" + listName).text($(".checked[data-collectionlist='"+listName+"']").length);
			$(".bwiki-collection-unchecknum-" + listName).text(num - $(".checked[data-collectionlist='"+listName+"']").length);
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
			$(".bwiki-collection-checknum-" + listName).text($(".checked[data-collectionlist='"+listName+"']").length);
			changeUserOptions("userjs-collectionList-" + listName, list.join(","))
			if(window.afterCollectionItemClick) window.afterCollectionItemClick(listName)
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
}

Bikit.libs.clickable = function() {
	$(".bikit-clickable").removeClass("bikit-clickable").addClass("bikited-clickable");
	$("head").prepend('<style>.bikited-clickable, .bwiki-clickable{cursor:pointer}</style>');
	$("body").on("click", ".bikited-clickable, .bwiki-clickable", function () {
		var opts = $(this).data();
        if (opts.options) {
            /* jslint evil: true */
            opts = $.extend({}, opts, (new Function('return ' + '{' + opts.options + '}'))());
            delete opts.options;
            $(this).removeAttr("data-options");
        }
        if (opts.toggleclass !== undefined) $(this).toggleClass(opts.toggleclass);
        if (opts.onclick !== undefined) eval(opts.onclick);
	});
};

Bikit.libs.overflow = function() {
	var overstyle="";
	$(".bikit-overflow").each(function() {
		$(this).removeClass("bikit-overflow");
		var opts = $(this).data();
		var overflowbox = $("<div></div>", {"class": "bikited-overflow bikited-overflow-hidden"});
		
		if(opts.overrow) {
			if($(this).find("tr").length < Number(opts.overrow) * (opts.strict ? 1:1.5)) return true;
			overstyle += `.bikited-overflow-hidden [data-overrow="${opts.overrow}"] tr:nth-of-type(n+${opts.overrow + 1}) {display:none}`
			overflowbox.addClass("bikited-overrow");
		} else if(opts.overheight) {
			if($(this).height() < Number(opts.overheight) * (opts.strict ? 1:1.5) ) return true;
			overstyle += `.bikited-overflow-hidden [data-overheight="${opts.overheight}"]{max-height:${opts.overheight};overflow:hidden}`
			overflowbox.addClass("bikited-overheight");
		}
		$(this).wrap(overflowbox);
		$(this).after($("<div></div>", {"class": "bwiki-overflow-button"}));
	})
		
	$("head").prepend(`<style>
			.bwiki-overflow-button{padding:0.3em 1em;cursor:pointer;opacity:0.8;text-align: center;}
			.bwiki-overflow-button:hover {opacity:1;}
			.bikited-overflow {display:inline-block;width:auto;position: relative;}
			.bikited-overflow .wikitable {margin-bottom:0;}
			.bikited-overflow .wikitable[data-overheight] {display: block; border:0}
			.bikited-overflow .wikitable + .bwiki-overflow-button {background:#e9edf2;opacity:0.8;border:1px #ccc solid;padding:0.3em 1em;text-align:center;}
			.bikited-overflow .wikitable[data-overrow] + .bwiki-overflow-button {border-top:0;}
			.bikited-overflow-visible .wikitable[data-overheight] + .bwiki-overflow-button {border-top:0;}
			.bikited-overflow-visible .bwiki-overflow-button:after{content:"收起"} 
			.bikited-overflow-hidden .bwiki-overflow-button:after{content:"展开"} 
			.bikited-overflow.bikited-overflow-hidden.bikited-overheight:after{content:" ";height:50%;width:100%;display:block;background:linear-gradient(0,white,transparent);bottom: 28px;position:absolute;pointer-events:none}
			${overstyle}
		</style>`);
		
	$("body").on("click", ".bwiki-overflow-button", function () {
		var xorClass = function(bool) {return bool ? "bikited-overflow-visible" : "bikited-overflow-hidden"};
		var target = $(this).parent(), xorFlag = target.hasClass(xorClass());
		target.addClass(xorClass(xorFlag)).removeClass(xorClass(!xorFlag))
	});
};

if(Bikit.util.getQueryParam("bikit") !== "test") Bikit.init();