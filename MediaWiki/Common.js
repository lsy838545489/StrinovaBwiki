/* 这里的任何JavaScript将为所有用户在每次页面载入时加载。 */
$(function(){
	// 公告栏
	mw.loader.load("/klbq/MediaWiki:Sitenotice.js?action=raw&ctype=text/javascript", "text/javascript");
	mw.loader.load("/klbq/MediaWiki:Sitenotice.css?action=raw&action=raw&ctype=text/css", "text/css");
	
	// [[模板:切换显示]]
	mw.loader.load("//wiki.biligame.com" + mw.util.wikiScript("") + "?title=MediaWiki:TextToggleDisplay.js&action=raw&ctype=text/javascript", "text/javascript");
	
	// sortableTableAnimation
	mw.loader.load("//wiki.biligame.com/klbq/index.php?title=User:54212577/sortableTableAnimation.js&action=raw&ctype=text/javascript");
	// 愚人节彩蛋
	var d = new Date();
	if (d.getMonth() === 3 && d.getDate() === 1) mw.loader.load("//wiki.biligame.com" + mw.util.wikiScript("") + "?title=MediaWiki:Fools.js&action=raw&ctype=text/javascript", "text/javascript");
	
	//编辑器插件SmartClick引入
	mw.loader.load("//wiki.biligame.com" + mw.util.wikiScript("") + "?title=MediaWiki:SmartClick.js&action=raw&ctype=text/javascript", "text/javascript");
	console.log("SmartClick.js initialized!");
});

/* == 评论区表情包 == */
$(function () {
	if ([0, -1].includes(mw.config.get('wgNamespaceNumber'))) {
    	"use strict";
		mw.loader.load(
			"//wiki.biligame.com/klbq/index.php?title=MediaWiki:CommentEmotes.js&action=raw&ctype=text/javascript",
			"text/javascript"
		);
	}
});

/* == 评论区消失修复 == */
// 来自sizau
function runOnDOMReady(callback) {
    try {
        if (document.readyState === "loading") {
            document.addEventListener("DOMContentLoaded", callback);
        } else {
            callback();
        }
    } catch (e) { }
}
(window.RLQ = window.RLQ || []).push([["ext.flowthread"], function () {
    runOnDOMReady(function () {
        if (
        	mw.config.get('wgNamespaceNumber') === 0 && 
        	($('.comment-container').length == 0 && 
        	mw.loader.getState('ext.flowthread') === 'ready') 
        ) {
            mw.loader.moduleRegistry["ext.flowthread"].script($, $);
        }
    });
}]);

/* == Audio模板 == */
try { 
	mw.loader.load("/klbq/MediaWiki:AudioPlayer.js?action=raw&ctype=text/javascript", "text/javascript");
	mw.loader.load("/klbq/MediaWiki:AudioPlayer.css?action=raw&action=raw&ctype=text/css", "text/css");
} catch(e) {}


/* == 加载Bikit == */
try { mw.loader.load("/klbq/MediaWiki:Bikit.js?action=raw&ctype=text/javascript", "text/javascript");} catch(e) {}


/* == 加载BWikiLocalUser == */
try { mw.loader.load("/klbq/MediaWiki:BWikiLocalUser.js?action=raw&ctype=text/javascript", "text/javascript");} catch(e) {}

/* == 加载DiffTool 爱来自 Lu(39886146) == */
try { mw.loader.load("/klbq/MediaWiki:DiffTool.js?action=raw&ctype=text/javascript", "text/javascript");} catch(e) {}


/* == 绕过B站链接过滤 == */
(function () {
    var linkAllowDomains = [
        "klbq.qq.com", "klbq.idreamsky.com", "klbqm.idreamsky.com", "www.strinova.com",
        "wegame.com.cn", "www.wegame.com.cn", "down.klbq.qq.com",
        "gugutack.com", "card.klbq.fsltech.cn", "gugutalk.github.io", 
        "strinova.org", "sh-1.strinova.fsltech.cn", "wiki.nekolaska.vip"
    ];

    document.body.addEventListener("click", function (e) {
        var a = e.target.closest("a");
        if (!a || !a.search) return;

        if (!/^\/linkfilter\/?$/i.test(a.pathname)) return;

        try {
            var searchParams = new URLSearchParams(a.search);
            var targetUrlStr = searchParams.get("url");
            if (!targetUrlStr) return;

            var targetUrl = new URL(targetUrlStr);

            if (linkAllowDomains.indexOf(targetUrl.hostname) !== -1) {
                searchParams.delete("url");
                searchParams.forEach(function (value, key) {
                    targetUrl.searchParams.append(key, value);
                });

                a.href = targetUrl.href;
                if (a.rel === "nofollow") a.rel = "noopener noreferrer";
            }
        } catch (err) {
        }
    }, true);
})();

/* == 为页面加载JS脚本或CSS样式表 == */
/* 参见[[模板:ResourceLoader]]*/
/* 将相关代码用改为DOM加载完成后运行，解决部分情况
模板:ResourceLoader加载不完全的问题 -- 芙兰朵露琪露诺 2021/8/11
转自碧蓝航线WIKI https://wiki.biligame.com/blhx/MediaWiki:Common.js */
function templateResourceLoader() {
	$('.resourceLoader').each(function() {
		var $x = $(this);
		var text = $.trim($x.text());
		
		if (!text) return;
		
		//加载模块
		if ($x.data('isModule') == true) 
			return mw.loader.load(text);	
		
		//自动补充MediaWiki命名空间
		var ns = text.match('^.*?:');
		if (!ns) text = 'MediaWiki:' + text;
		
		//加载CSS样式表
		var mime = ($x.data('mime') || "text/javascript").toLowerCase();
		if (mime == "text/css") {
			if (text.slice(-4).toLowerCase() !== '.css') text = text + '.css';
			//if ($x.data('debug') !== true) text = text + '&debug=false';
			return mw.loader.load("//wiki.biligame.com/klbq/index.php?title="+text+"&action=raw&ctype=text/css", "text/css");
		}
		
		//加载JS脚本
		if (ns && ns[0].toLowerCase() !== 'mediawiki:') {
			return console.log('ResourceLoader: 不允许加载MediaWiki以外的js脚本');
		}
		if (text.slice(-3).toLowerCase() !== '.js') text = text + '.js';
		console.log('ResourceLoader: 加载' + text);
		//if ($x.data('debug') !== true) text = text + '&debug=false';
		return mw.loader.load("//wiki.biligame.com/klbq/index.php?title="+text+"&action=raw&ctype=text/javascript", "text/javascript");
	});
}

function loadAfterDOM(func) {
	if (document.readyState == 'loading') {
		document.addEventListener('DOMContentLoaded', func);
	} else {
		func();
	}
}
loadAfterDOM(templateResourceLoader);

/* == 百度访问用户统计 == */
try {
        var _hmt = _hmt || [];
        (function () {
            var hm = document.createElement("script");
            hm.src = "https://hm.baidu.com/hm.js?802b0d32fda76341ff7bee681f5c6f60";
            var s = document.getElementsByTagName("script")[0];
            s.parentNode.insertBefore(hm, s);
        })();
    } catch (e) { }
    
/* == 谷歌访问用户统计 == */
try {
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', 'G-RD5DKX22BY');

    var gaScript = document.createElement('script');
    gaScript.async = true;
    gaScript.src = 'https://www.googletagmanager.com/gtag/js?id=G-RD5DKX22BY';
    document.head.appendChild(gaScript); // 直接插入head尾部
} catch (e) {
    console.warn('Google Analytics加载失败:', e);
}

/* == bootstrap == */
try {
	$(function () {
    	$('[data-toggle="tooltip"]').tooltip();
    	$('[data-toggle="popover"]').popover();
	});
} catch (e) { }

/* == 编辑摘要 == */
//参考Wikipedia:MediaWiki:Common.js/edit.js
if (mw.config.get('wgAction') == "edit" || mw.config.get('wgAction') == "submit" || mw.config.get('wgCanonicalSpecialPageName') == 'Search') { // 编辑页面
  
( function( $, mw ) { $( function() {
    if ( $( '#editform input[name=wpSection]' ).val() === 'new' ) {
        if ( $( '#no-new-title' ).length ) {
            $( '#wpSummary' ).attr( 'disabled', true );
        }
        return;
    }
    $( '#wpSummaryLabel .mw-summary-preset' ).on( 'click', '.mw-summary-preset-item a', function( e ) {
        e.preventDefault();
        var $this = $( this ), summary = $( '#wpSummary' ).val();
        var $item = $this.parent( '.mw-summary-preset-item' );
        summary = summary.replace( /\s+$/g, '' );
        if ( summary != '' ) {
            summary += ' ';
        }
        summary += $item.attr( 'title' ) || $this.text();
        $this.replaceWith( $this.contents() );
        $( '#wpSummary' ).val( summary ).focus();
    } );
} ); } )( jQuery, mediaWiki );
}

/* == Bwiki Tab套娃修复 == */
(window.RLQ = window.RLQ || []).push([ ["mediawiki.extra.bili", "jquery"], function() {
    $(".resp-tabs .resp-tabs-list .bili-list-style").unbind("click").click(function() {
        $(this).addClass("active").siblings().removeClass("active");
        var e = $(this).index();
        $(this).parents(".resp-tabs").eq(0).children(".resp-tabs-container").children(".resp-tab-content").eq(e).show().siblings().hide(),
        $(".resp-accordion-handle").hide()
    })
 }]);