//本插件由赛马娘wiki》素子ちゃん_official编写，邮件：stanergy-gin@outlook.com
//React相关的编辑支持集成在本插件中：包括JSX高亮、Babel同步转码
//说明文档地址：https://wiki.biligame.com/umamusume/SmartClick%E6%96%87%E6%A1%A3
//crated by Stanergy Gin
//Version 2.1.1

//████████
//█载入插件指引█
//████████

//①将本js文件放在MediaWiki:SmartClick.js下，并在自己站点的Common.js加入以下代码：
/*----------------------------------------------------------------------
//编辑器插件SmartClick引入
$(function(){
	mw.loader.load("//wiki.biligame.com" + mw.util.wikiScript("") + "?title=MediaWiki:SmartClick.js&action=raw&ctype=text/javascript", "text/javascript");
	console.log("SmartClick.js initialized!");
});
-----------------------------------------------------------------------*/
//②在自己站点的Common.css加入以下代码：
/*----------------------------------------------------------------------
//SmartClick修正
.popover-content{word-break:break-all}
-----------------------------------------------------------------------*/

//███████
//█自定义参数█
//███████


const settings = 
	{
		//SmartClick editor settings（false跳转到查看，true跳转到编辑） 默认TFFFT
		"JS/CSS": true,
		"模板": false,
		"Data数据/页面引入": false,
		"数据库": false,
		"Widget组件": true,
		
		//SmartClick quick panel settings（false覆盖当前页面，true跳转到新页面） 默认FFFF
		"编辑": false,
		"历史": false,
		"删除": false,
		"刷新": false
	};
	
//说明文档的Url
const explainUrlEditor = 'https://wiki.biligame.com/umamusume/SmartClick%E6%96%87%E6%A1%A3/EditorPart';
const explainUrlHistory = 'https://wiki.biligame.com/umamusume/SmartClick%E6%96%87%E6%A1%A3/HistoryEdit';
//hover链接时站点自定义光标的Url
const cursorUrl = "https://patchwiki.biligame.com/images/umamusume/a/ae/o0htx7vga5rt00mdmj8lee5unlcfz8y.png";	
	
	
 //           .,,       .,:;;iiiiiiiii;;:,,.     .,,
 //         rGB##HS,.;iirrrrriiiiiiiiiirrrrri;,s&##MAS,
 //        r5s;:r3AH5iiiii;;;;;;;;;;;;;;;;iiirXHGSsiih1,
 //           .;i;;s91;;;;;;::::::::::::;;;;iS5;;;ii:
 //         :rsriii;;r::::::::::::::::::::::;;,;;iiirsi,
 //      .,iri;;::::;;;;;;::,,,,,,,,,,,,,..,,;;;;;;;;iiri,,.
 //   ,9BM&,            .,:;;:,,,,,,,,,,,hXA8:            ..,,,.
 //  ,;&@@#r:;;;;;::::,,.   ,r,,,,,,,,,,iA@@@s,,:::;;;::,,.   .;.
 //   :ih1iii;;;;;::::;;;;;;;:,,,,,,,,,,;i55r;;;;;;;;;iiirrrr,..
 //  .ir;;iiiiiiiiii;;;;::::::,,,,,,,:::::,,:;;;iiiiiiiiiiiiri
 //  iriiiiiiiiiiiiiiii;;;::::::::::::::::;;;iiiiiiiiiiiiiiiir;
 // ,riii;;;;;;;;;;;;;:::::::::::::::::::::::;;;;;;;;;;;;;;iiir.
 // iri;;;::::,,,,,,,,,,:::::::::::::::::::::::::,::,,::::;;iir:
 //.rii;;::::,,,,,,,,,,,,:::::::::::::::::,,,,,,,,,,,,,::::;;iri
 //,rii;;;::,,,,,,,,,,,,,:::::::::::,:::::,,,,,,,,,,,,,:::;;;iir.
 //,rii;;i::,,,,,,,,,,,,,:::::::::::::::::,,,,,,,,,,,,,,::i;;iir.
 //,rii;;r::,,,,,,,,,,,,,:,:::::,:,:::::::,,,,,,,,,,,,,::;r;;iir.
 //.rii;;rr,:,,,,,,,,,,,,,,:::::::::::::::,,,,,,,,,,,,,:,si;;iri
 // ;rii;:1i,,,,,,,,,,,,,,,,,,:::::::::,,,,,,,,,,,,,,,:,ss:;iir:
 // .rii;;;5r,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,sh:;;iri
 //  ;rii;:;51,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.:hh:;;iir,
 //   irii;::hSr,.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,.,sSs:;;iir:
 //    irii;;:iSSs:.,,,,,,,,,,,,,,,,,,,,,,,,,,,..:135;:;;iir:
 //     ;rii;;:,r535r:...,,,,,,,,,,,,,,,,,,..,;sS35i,;;iirr:
 //      :rrii;;:,;1S3Shs;:,............,:is533Ss:,;;;iiri,
 //       .;rrii;;;:,;rhS393S55hh11HC5S3393Shr:,:;;;iirr:
 //         .;rriii;;;::,:;is1h555555h1si;:,::;;;iirri:.
 //           .:irrrii;;;;;:::,,,,,,,,:::;;;;iiirrr;,
 //              .:irrrriiiiii;;;;;;;;iiiiiirrrr;,.
 //                 .,:;iirrrrrrrrrrrrrrrrri;:.
 //                       ..,:::;;;;:::,,.


class Api {
	constructor(){
		this.site = `https://wiki.biligame.com${mw.util.wikiScript("api")}`;
		this.defaultSymbol = Symbol("default");
		this.queue = [];
		$.ajaxSettings.timeout='10000';
	}
	GET(param, symbol=this.defaultSymbol){
		let req =  $.get(this.site, param,()=>this.queueOUT(symbol));
		this.queueIN(req, symbol);
		return req;
	}
	POST(param, symbol=this.defaultSymbol) {
		let req = $.post(this.site, param,()=>this.queueOUT(symbol));
		this.queueIN(req, symbol);
		return req;
	}
	queueIN(req, symbol=this.defaultSymbol) {
		if(this.queue[symbol]) {
			this.queue[symbol].push(req);
		} else {
			this.queue[symbol] = [req];
		}
	}
	queueOUT(symbol=this.defaultSymbol) {
		if (this.queue[symbol]) {
			delete this.queue[symbol];
		}
	}
	abort(symbol=this.defaultSymbol) {
		if (this.queue[symbol]) {
			this.queue[symbol].map(item => item.abort());
			const len = this.queue[symbol].length;
			delete this.queue[symbol];
			return {"num": len, "symbol": symbol, "queue": this.queue};
		} else {
			
		}
		return {"num": 0, "symbol": symbol, "queue": this.queue};
	}
}

//站点名
const apiUrl = mw.config.get("wgGameName") || "klbq";

//编辑器对象
let editor; let editorType; let cnt = 0;
let queryEditor = setInterval(function() {
	editor = document.querySelector('.CodeMirror') !== null? document.querySelector('.CodeMirror').CodeMirror: ($(".editor").length !== 0? ace.edit($(".editor")[0]): "none");
	editorType =  document.querySelector('.CodeMirror') !== null? "CodeMirror": ($(".editor").length !== 0? "Ace": "none");
	cnt += 1;
	if (editor !== null && editor !== "none" && editor !== undefined && editorType !== null && editorType !== "none" && editorType !== undefined) {
		clearInterval(queryEditor);
	}
	if (cnt >= 20) {
		clearInterval(queryEditor);
	}
}, 500);

//用于模板:parse的parseLoader解析
let parseIdx = 0;
let parseInter = setInterval(() => {
	if (typeof $.get !== "function") {
		++parseIdx;console("no jq");
	} else {
		parseLoader();
		clearInterval(parseInter);
	}
	if (parseInter > 10) {
		clearInterval(parseInter);
	}
}, 200);
//解析parseLoader
function parseLoader() {
	$(".parseLoader").each(function (idx, el) {
		const $el = $(el);
		wikiParserPro($el.text()).then(res => {
			$el.after(`<div class="parseLoader_output-${idx}"></div>`);
			// $el.text("before parse:" + $el.text() + "; after parse(" + res + "):" + JSON.stringify(res));
			// alert("before parse:" + $el.text() + "; after parse(" + res + "):" + JSON.stringify(res));
			$(`.parseLoader_output-${idx}`).html(res);
			loadTippy();
			if ($el.attr("data-debug") !== "true") {
				$el.remove();
			}
		}, err => $el.after(`加载失败，请检查网络！`));
	});
}
//加载弹窗
function loadTippy() {
	$('.popup').each(function (i, e) {
		if(e.children[1]) {
    		e.children[1].style.display = 'block';
    		tippy6(e.children[0], {
	        	content: e.children[1],
	        	interactive: true,
	        	arrow: true,
	        	theme: 'light-border',
	        	size: 'large',
	        	maxWidth: e.children[1].dataset.size === "none"? "none": parseInt(e.children[1].dataset.size)
	    	});
		}
	});
}
	
//SmartClick.js总入口
const href = decodeURIComponent(window.location.href);
// //大型调试时禁用除管理员外的SmartClick功能
// if (mw.config.values.wgUserName === "387538174") {
	if (/action=edit/.test(href) || /action=submit/.test(href)) {
		let queryEditor = setInterval(function() {
			if (editor !== null && editor !== "none" && editor !== undefined && editorType !== null && editorType !== "none" && editorType !== undefined) {
				clearInterval(queryEditor);
				SC_Editor();
				console.log("%c SmartClick.js %c Editor Part Running", "color: #fff; padding: 5px 0; background: olive;", "padding: 5px 5px 5px 0; background: #e5e5ff; color:olive");
			}
			if (cnt >= 20) {
				clearInterval(queryEditor);
				console.log("%c SmartClick.js %c No Editor Found", "color: #fff; padding: 5px 0; background: darkred;", "padding: 5px 5px 5px 0; background: #e5e5ff; color:darkred");
			}
		}, 500);	
	} 
	else if(!(/特殊:/.test(href) || /首页/.test(href))){
		console.log("%c SmartClick.js %c Panel Part Running", "color: #fff; padding: 5px 0; background: olive;", "padding: 5px 5px 5px 0; background: #e5e5ff; color:olive");
	}
// } else {
// 	let bannedInform = `<div class="alert alert-warning alert-dismissable" role="alert" id="alert-banned-info">` +
// 		`<button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>` +
// 		`<p><span style="font-weight:bold">SmartClick.js</span>&nbsp;&nbsp;本次SmartClick的维护需要全局禁用所有功能，预计2023/03/05前重新开放&nbsp;&nbsp;` +
// 		`</p></div>`;
// 	$(".wikiEditor-ui").before(`<div id="alert-area"></div>`);
// 	$("#alert-area").css("width", "100%");
// 	$("#alert-area").html(bannedInform);
// }


	
//SmartClick Editor部分载入函数（sub_topcell_A）
function SC_Editor() {
	let basicInform = `<div class="alert alert-info alert-dismissable" role="alert" id="alert-basic-info">` +
		`<button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>` +
		`<p><span style="font-weight:bold">SmartClick.js</span>&nbsp;&nbsp;按alt快速定位编辑区；按住alt可以用鼠标查看一些字段，点击可快速跳转&nbsp;&nbsp;` +
		`<a href="${explainUrlEditor}" style="color:#2f6782; font-size:12px; text-decoration:none;" class="glyphicon glyphicon-question-sign" target="_blank">` + 
		`</p></div>`;
	$(".wikiEditor-ui").before(`<div id="alert-area"></div>`);
	$("#alert-area").css("width", "100%");
		
	//获取页面id
	let pageNo = mw.config.values.wgRelevantArticleId.toString(); 
	let hEdit = null;
	
	//修正编辑器字体，使其不受浏览器设置影响
	if (editorType === "Ace") {
		//$(".ace_content").css("font", "initial");
		editor.setOptions({
		  fontFamily: "consolas,monospace", fontSize: "14px"
		});
	} else if (editorType === "CodeMirror") {
		// $(".CodeMirror-line").css("font-family", "consolas");
		// $(".CodeMirror-line").css("font-size", "14px")
		// 关闭拼写检查
		$(".CodeMirror-lines").attr("spellcheck", "false");
		// let pending = false;
		editor.on("change", () => {
			// if (pending) return;
			// pending = true;
			$(".CodeMirror-lines").attr("spellcheck", "true");
			$(".CodeMirror-lines").attr("spellcheck", "false");
			// setTimeout(() => {
			// 	$(".CodeMirror-lines").attr("spellcheck", "")
			// 	pending = false;
			// }, 1000);
		});
		// widget高亮（优先检测赛马娘wiki内的JS源）
		if (mw.config.values.wgPageName.toLowerCase().includes("widget:")) {
			const js = new Promise((resolve,reject) => {
				let xhr = $.getScript("//wiki.biligame.com/umamusume/index.php?title=MediaWiki:CodeMirror_javascript.min.js&action=raw&ctype=text/javascript",() => {
					xhr.responseText.length? resolve("js-wiki"): 
						$.getScript("https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.40.0/mode/javascript/javascript.min.js", () => {
							resolve("js-cdn");
						});
				});	
			});
			const css = new Promise((resolve,reject) => {
				let xhr = $.getScript("//wiki.biligame.com/umamusume/index.php?title=MediaWiki:CodeMirror_css.min.js&action=raw&ctype=text/javascript",() => {
					xhr.responseText.length? resolve("css-wiki"): 
						$.getScript("https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.40.0/mode/css/css.min.js", () => {
							resolve("css-cdn");
						});
				});	
			});
			const xml = new Promise((resolve,reject) => {
				let xhr = $.getScript("//wiki.biligame.com/umamusume/index.php?title=MediaWiki:CodeMirror_xml.min.js&action=raw&ctype=text/javascript",() => {
					xhr.responseText.length? resolve("xml-wiki"): 
						$.getScript("https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.40.0/mode/xml/xml.min.js", () => {
							resolve("xml-cdn");
						});
				});	
			});
			Promise.all([js, css, xml]).then(() => {
				let xhr = $.getScript("//wiki.biligame.com/umamusume/index.php?title=MediaWiki:CodeMirror_htmlmixed.min.js&action=raw&ctype=text/javascript",() => {
					xhr.responseText.length? editor.setOption("mode", "htmlmixed"): 
						$.getScript("https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.40.0/mode/htmlmixed/htmlmixed.min.js", () => {
							editor.setOption("mode", "htmlmixed");
						});
				});	
			});
		}
		// 改字体并刷新（改字体后光标会与实际位置对不上，要刷新编辑器）
		const style = $(`<style>pre.CodeMirror-line {font-family: consolas,monospace !important; font-size: 14px}
		pre.CodeMirror-line.cm-mw-section-1{font-size: 1.8em !important;}
		pre.CodeMirror-line.cm-mw-section-2{font-size: 1.6em !important;}
		pre.CodeMirror-line.cm-mw-section-3{font-size: 1.4em !important;}
		pre.CodeMirror-line.cm-mw-section-4{font-size: 1.2em !important;}
		pre.CodeMirror-line.cm-mw-section-5,pre.CodeMirror-line.cm-mw-section-6{font-size: 14px !important;}</style>`);
		$(".wikiEditor-ui").append(style);
		editor.refresh();
	}
	
	
	//记录focus状态
	let isFocus = false;
	editor.on("focus", function(){
		isFocus = true;
		dealLocal();
	});
	editor.on("blur", function() {
		isFocus = false;
		dealLocal();
	});
	
	if(isHistoryEdit()) {
		//在文档顶部载入插件说明
		let ets = 0;
		for(const key in hEdit) {
			if(key === pageNo) {
				const hE = hEdit[key];
				ets =  hE.ets;
			}
		}
		let time = getDuration(parseInt((Date.now() - ets)/1000));
		$("#alert-area").html(`<div class="alert alert-success alert-dismissable" role="alert" id="alert-edit-history">` +
			`<p><span style="font-weight:bold">SmartClick.js</span>&nbsp;&nbsp;检测到您在` +
			`<span style="font-weight:bold">${time}</span>前最后的编辑位置，按alt快速定位（开始编辑后失效）&nbsp;&nbsp;` +
			`<a href="${explainUrlHistory}" style="color:#276128; font-size:12px; text-decoration:none;" class="glyphicon glyphicon-question-sign" target="_blank">` + 
			`</p></div>`);
	} else {
		//在编辑器顶部载入插件说明
		$("#alert-area").html(basicInform);
	}
	
	//启用自动补全
	if (editorType === "Ace") {
		editor.on("change", function(e){
		　　editor.execCommand("startAutocomplete");
		});
	}

	/* 快速提交JS、CSS、Widget、JSX、模板 以及 JSX高亮支持 */
	
	//改动后恢复页面离开提示
	editor.on("change", () => {
		$(window).on("beforeunload", () => "unload");
		changeColor("init");
		$("#msg-babel").html("在上次提交后，你已做出改动")
		$("#msg-submitter").html("在上次提交后，你已做出改动")
		$("#msg-widget").html("在上次提交后，你已做出改动")
	});
	//原始提交栏按钮取消beforeunload
	$(".editButtons span[id^='wp']").click(() => $(window).off("beforeunload"));
	//判断widget
	let pageNameJudge = mw.config.values.wgPageName.toLowerCase();
	if(pageNameJudge.includes("widget:")) {
		initWidgetTemplate("Widget");
	}
	//判断模板
	else if(pageNameJudge.includes("模板:") || pageNameJudge.includes("template:")) {
		initWidgetTemplate("模板");
	}
	// 不启用，免得普通用户好奇
	// //判断页面
	// else if (editorType === "CodeMirror") {
	// 	initWidgetTemplate("页面");
	// }
	
	//判断CSS
	if (editorType === "Ace" && editor.session.getMode().$id === "ace/mode/css") {
		initSubmitter("CSS");
	}
	//判断Lua
	if (editorType === "Ace" && editor.session.getMode().$id === "ace/mode/lua") {
		initSubmitter("Lua");
	}
	
	//判断JS/JSX
	let i = 0; let babelInit = false; let submitterInit = false;
	let langJudge = setInterval(() => {
		let annotation, error, jsxError;
		i++;
		if (i > 6) clearInterval(langJudge);
		if (editorType === "Ace" && editor.session.getMode().$id !== "ace/mode/css" && editor.session.getMode().$id !== "ace/mode/lua" ) {
			annotation = editor.session.getAnnotations();
			if (annotation.length) {
				error = annotation.filter(obj => obj.type === "error");
				if (annotation && error.length > 0) {
					$(".lang-switch").remove();
					$("#wikiEditor-ui-toolbar").append(`<div class="lang-switch" style="position:absolute;\
						right: 0;height: 100%;top: 0;padding: 4px 6px;font-size:16px;user-select:none;cursor:pointer;\
						background: #dddddd;">JSX</div>`);
					editor.session.setMode("ace/mode/javascript");
					editor.session.setTabSize(2);
					editor.session.setUseWorker(false);
					$("div[id$='-submitter'").hide();
					$("div[id$='-babel'").show();
					babelInit? "":initTransformer();
					babelInit = true;
				} else {
					$(".lang-switch").remove();
					$("#wikiEditor-ui-toolbar").append(`<div class="lang-switch" style="position:absolute;\
						right: 0;height: 100%;top: 0;padding: 4px 6px;font-size:16px;user-select:none;cursor:pointer;\
						background: #dddddd;">JS</div>`);
					editor.session.setMode("ace/mode/javascript");
					editor.session.setTabSize(4);
					editor.session.setUseWorker(true);
					$("div[id$='-babel'").hide();
					$("div[id$='-submitter'").show();
					submitterInit? "":initSubmitter("JS");
					submitterInit = true;
				}
				clearInterval(langJudge);
			} else {
				$(".lang-switch").remove();
				$("#wikiEditor-ui-toolbar").append(`<div class="lang-switch" style="position:absolute;\
					right: 0;height: 100%;top: 0;padding: 4px 6px;font-size:16px;user-select:none;cursor:pointer;\
					background: #dddddd;">JS</div>`);
				editor.session.setMode("ace/mode/javascript");
				editor.session.setTabSize(4);
				editor.session.setUseWorker(false);
				if (i > 6) {
					$("div[id$='-babel'").hide();
					$("div[id$='-submitter'").show();
					submitterInit? "":initSubmitter("JS");
					submitterInit = true;
				}
			}
			$(".lang-switch").hover(() => {
					$(".lang-switch").css("background", "#cccccc")
				},() => {
					$(".lang-switch").css("background", "#dddddd");
				});
			$(".lang-switch").click(() => {
				clearInterval(langJudge);
				let $el = $(".lang-switch");
				if($el.text() === "JS") {
					$el.text("JSX");
					editor.session.setMode("ace/mode/javascript");
					editor.session.setTabSize(2);
					editor.session.setUseWorker(false);
					$("div[id$='-submitter'").hide();
					$("div[id$='-babel'").show();
					babelInit? "":initTransformer();
					babelInit = true;
				} 
				else if($el.text() === "JSX") {
					$el.text("JS");
					editor.session.setMode("ace/mode/javascript");
					editor.session.setTabSize(4);
					editor.session.setUseWorker(true);
					$("div[id$='-babel'").hide();
					$("div[id$='-submitter'").show();
					submitterInit? "":initSubmitter("JS");
					submitterInit = true;
				}
			});
		}
	}, 500);
	/* 快速提交JS、CSS、Widget、JSX 以及 JSX高亮支持(结束) */
	
	//更新绑定
	let updateSwitch = true; //更新频率限制开关
	setInterval(function(){updateSwitch = true}, 2000);
	$(document).keydown(function(event) {
		if(event.altKey && updateSwitch) {
			bindSmartClick(settings);
			updateSwitch = false;
		}
	});
	$(document).keyup(function(event) {
		if(event.altKey) {
			updateSwitch = true;
		}
	});
	
	//解析{{parse|}}模板的解析标记(%XXX%)
	if (editorType === "CodeMirror" /*&& mw.config.values.wgUserName === "387538174"*/) {
		//还原解析标记(%XXX%)
		let text = editor.getValue();
		for (let wt of getWikiText(text)) {
			const plain = wt;
			wt = wt.match(new RegExp("(?<=(<nowiki>))([\\s\\S]*)(?=(<\\/nowiki>))", "g"));
			if (!wt) {
				console.log("parse: no mark requires parsed");
				continue;
			}
			wt = wt[0].replaceAll("</nowiki>", "(%").replaceAll("<nowiki>", "%)");
			text = text.replace(plain, wt);
		}
		editor.setValue(text);
		setTimeout(() => {
			$(window).off("beforeunload");
			$("#msg-widget").html("高效调试模板代码");	
		}, 400);
		//解析解析标记(%XXX%)
		$("#wpSave").click(() => {
			let textSave = editor.getValue();
			const ig = ignorePre(textSave);
			textSave = ig.output;
			map = ig.map;
			let wikitext = getWikiText(textSave);
			for (let wt of wikitext) {
				const plain = wt;
				wt = `<nowiki>${wt}</nowiki>`;
				wt = wt.replaceAll("(%", "</nowiki>").replaceAll("%)", "<nowiki>");
				textSave = textSave.replace(plain, wt);
			}
			textSave = parsePre(textSave, map);
			editor.setValue(textSave);
			setTimeout(()=>$(window).off("beforeunload"), 600);
		});
		//解析解析标记(%XXX%)
		$("#wpPreview").click(() => {
			let textPre = editor.getValue();
			const ig = ignorePre(textPre);
			textPre = ig.output;
			map = ig.map;
			let wikitext = getWikiText(textPre);
			for (let wt of wikitext) {
				const plain = wt;
				wt = `<nowiki>${wt}</nowiki>`;
				wt = wt.replaceAll("(%", "</nowiki>").replaceAll("%)", "<nowiki>");
				textPre = textPre.replace(plain, wt);
			}
			textPre = parsePre(textPre, map);
			editor.setValue(textPre);
			setTimeout(()=>$(window).off("beforeunload"), 600);
		});
	}
	//匹配需要解析的片段
	function getWikiText(text) {
		const ig = ignorePre(text);
		let textIg = ig.output;
		const map = ig.map;
		let parse = textIg.match(new RegExp("(?<=(\\{\\{parse[\\s]?\\|))([\\s\\S]+?)(?=(\\|[\\s]?#end[\\s]?\\}\\}))", "g"));
		console.log(parse)
		parse = parse === null? []: parse;
		let wikitext = [];
		try {
			wikitext = parse.map(item => item.match(new RegExp("(?<=(wikitext=))([\\s\\S]+)", "g"))[0]);
		} catch(e) {
			console.log(e);
			alert(`parse模板解析错误，请前往模板:parse页面查看具体的用法`);
        }
        return wikitext;
	}
	//替换pre代码片段
	function ignorePre(text) {
		let output = text;
		let syntax = text.match(new RegExp("(?<=(<syntaxhighlight))([\\s\\S]*?)(?=(<\\/syntaxhighlight>))", "g"));
		let pre = text.match(new RegExp("(?<=(<pre>))([\\s\\S]*?)(?=(<\\/pre>))", "g"));
		let map = new Map();
		syntax = !syntax? []: syntax;
		pre = !pre? []: pre;
		[...syntax, ...pre].map((item, idx) => {
			output = output.replace(item, `<%-ignore#${idx}-%>`);
			map.set(`<%-ignore#${idx}-%>`, item);
		});
		return {output: output, map: map}
	}
	//pre代码片段还原
	function parsePre(text, map) {
		let output = text;
		for (let [key, val] of map) {
			output = output.replace(key, val);
		}
		return output;
	}
	
	
	//快速定位
	let switchOnce = false;
	//setInterval(function(){switchLocate = true}, 2000);
	let handlerKeydownLocate = function(event) {
		if(event.altKey && switchOnce) {
			//alt快速定位
			if ($(".wiki-nav-celling").length !== 0) {
				window.scrollTo($(window).scrollLeft(), $(".wikiEditor-ui-bottom").offset().top-120);
			} else {
				window.scrollTo($(window).scrollLeft(), $(".wikiEditor-ui-bottom").offset().top-170);
			}
			// //高亮代码堆栈
			// if (isFocus) {
			// 	queryNode();
			// 	highlightNode();
			// }
			switchOnce = false;
		}
	}
	let handlerKeyupLocate = function(event) {
		event.preventDefault();
		switchOnce = true;
		// //清除代码堆栈高亮
		// clearNode();
		$(document).unbind("keyup", handlerKeyupLocate).keyup(handlerKeyupLocate);
	}
	$(document).keydown(handlerKeydownLocate);
	$(document).keyup(handlerKeyupLocate);
	
	//计算缓存
	function dealLocal() {
		let obj = {"st":"", "sl":"", "cl":"", "cc":"", "ets":"", "et":""};
		//{"scrollTop": "", "scrollLeft": "", "cursorLine": "", "cursorCh": "", "editionTimestamp": 0, "editorType": "unknown"};
		let hEdit;
		try {
			hEdit = JSON.parse(localStorage.getItem(`MediaWiki_SmartClick_historyEdit_${mw.config.values.wgGameName}`));
		} catch(e) {
			console.log(e);
		}
		if (hEdit === null || $.isEmptyObject(hEdit) || typeof hEdit !== "object") {
			hEdit = {};
		}
		if (editorType === "CodeMirror") {
			obj.st = parseInt(editor.getScrollInfo().top);
			obj.sl = parseInt(editor.getScrollInfo().left);
			obj.cl = editor.getCursor().line;
			obj.cc = editor.getCursor().ch;
			obj.ets = Date.now();
			obj.et = "CM";
		} else if (editorType === "Ace") {
			obj.st = parseInt(editor.session.getScrollTop());
			obj.sl = parseInt(editor.session.getScrollLeft());
			obj.cl = editor.getCursorPosition().row;
			obj.cc = editor.getCursorPosition().column;
			obj.ets = Date.now();
			obj.et = "Ace";
		}
		hEdit[pageNo] = obj;
		if (pageNo !== 0) {
			localStorage.setItem(`MediaWiki_SmartClick_historyEdit_${mw.config.values.wgGameName}`, JSON.stringify(hEdit));
		}
	}
	
	
	//退出时更新缓存
	$(window).on("unload", function() {
		if (isFocus) {
			dealLocal();
		}
	});
	
	//定时更新缓存
	setInterval(function() {
		if (isFocus) {
			dealLocal();
		}
	}, 5000)
	
	//解析代码堆栈
	function queryNode() {
	    const $tag = $(".cm-mw-htmltag-name, .cm-mw-parserfunction-name,  .cm-mw-parserfunction-bracket");
	    let node = [];
	    let stack = 0;
	    $tag.each((idx, el) => {
	        const [$el, $prev, $next] = [$(el), $(el).prev(), $(el).next()];
	        if (matchSingle($el.text())) return;
	        if ($prev.text().includes("<") && !$prev.text().includes("</") || $prev.text().includes("{{")) {
	            node.push({name: $el.text()});
	            stack += 1;
	            $el.data("node", {tag: "start", stack: stack});
	        }
	        else if ($prev.text().includes("</") || ($el.hasClass("cm-mw-parserfunction-bracket") && $el.text().includes("}}"))) {
	            const last = node.pop();
	            stack -= 1;
	            $el.data("node", {tag: "end", stack: stack});
	        }
	    });
	    return {status: true, tag: null}
	    
	    function matchSingle(tagName) {
	        let singleTagName = ["br", "hr", "img", "input", "col"];
	        return singleTagName.filter(single => tagName.toLowerCase().includes(single)).length? true: false;
	    }
	}
	//高亮代码堆栈
	function highlightNode() {
	    const $tag = $("span[class^='cm-mw-']");
	    const macaron = ["inherit", "#d9b8f1", "#f1ccb8", "#f1f1b8", "#b8f1ed", "#b8f1cc", "#e7dbca", "#b8d38f", "#ff9b6a","#f1b8f1",
	        "#ffe647", "#e49f5e", "#ff8444", "#ac5e74", "#f0b735", "#d08a8a"];
	    let currentStack = 0; let prevStack = 0; let passNext = false;
	    $tag.each((idx, el) => {
	        const $el = $(el);
	        const node = $el.data("node");
	        if (node) {
	            currentStack = node.stack;
	        }
	        if (passNext) {
	            passNext = false;
	        } else {
	            $el.css("background", macaron[currentStack]);
	            $el.css("filter", "brightness(1.15)"); 
	            if (node && node.tag === "end") {
	                if ($el.hasClass("cm-mw-parserfunction-bracket") && $el.text().includes("}}") ) {
	                    $el.css("background", macaron[currentStack + 1]);
	                    $el.css("filter", "brightness(0.9)");
	                }
	                let $next = $el.next(); let $handle = $next;
	                if ($next.text().includes("></") || $el.text().includes("}}{{") ) {
	                    if ($next.text().includes("></")) {
	                        $handle = $next;
	                        $next.after(`<span class="cm-mw-htmltag-bracket  cm-mw-temp">&gt;</span><span class="cm-mw-htmltag-bracket  cm-mw-temp">&lt;/</span>`);
	                    }
	                    if ($el.text().includes("}}{{")) {
	                        $handle = $el
	                        $el.after(`<span class="cm-mw-parserfunction-bracket cm-mw-temp">}}</span><span class="cm-mw-parserfunction-bracket  cm-mw-temp">{{</span>`);
	                    }
	                    const $temp = $next.next();
	                    $handle.hide();
	                    $handle = $temp;
	                    $handle.next().css("background", macaron[currentStack]);
	                    $handle.next().css("filter", "brightness(0.9)");
	                    $handle.css("border-radius", "4px 0 0 4px");
	                }
	                $el.css("background", macaron[currentStack + 1]);
	                $handle.css("background", macaron[currentStack + 1]);
	                $handle.css("filter", "brightness(0.9)");
	                $handle.css("border-radius", "0 4px 4px 0");
	                passNext = true;
	            }
	            else if(node && node.tag === "start") {
	                let $prev = $el.prev();
	                if ($prev.text().includes("></") || $prev.text().includes("}}{{") ) {
	                    if ($prev.text().includes("></"))
	                        $prev.before(`<span class="cm-mw-htmltag-bracket cm-mw-temp">&gt;</span><span class="cm-mw-htmltag-bracket cm-mw-temp">&lt;</span>`);
	                    if ($prev.text().includes("}}{{"))
	                        $prev.before(`<span class="cm-mw-parserfunction-bracket cm-mw-temp">}}</span><span class="cm-mw-parserfunction-bracket cm-mw-temp">{{</span>`);
	                    const $temp = $prev.prev();
	                    $prev.hide();
	                    $prev = $temp;
	                    $prev.prev().css("background", macaron[currentStack + 1]);
	                    $prev.prev().css("filter", "brightness(0.9)");
	                }
	                $el.css("background", macaron[currentStack]);
	                $el.css("filter", "brightness(0.9)");
	                $prev.css("background", macaron[currentStack]);
	                $prev.css("filter", "brightness(0.9)");
	                $prev.css("border-radius", "4px 0 0 4px");
	            }   
	        }
	        if ($el.hasClass("cm-mw-templatevariable-name") || $el.hasClass("cm-mw-templatevariable")
	            || $el.hasClass("cm-mw-templatevariable-bracket") || $el.hasClass("cm-mw-templatevariable-delimiter") ) {
	            $el.css("background", "#56ff46");
	        }
	    });
	}
	//清除堆栈高亮
	function clearNode() {
	    $("span[class^='cm-mw-']").css("background", "inherit");
	    $("span[class^='cm-mw-']").css("filter", "inherit");
	    $("span[class^='cm-mw-']").show();
	    $(".cm-mw-temp").remove();
	}
	
	//初始化babel转化器
	function initTransformer() {
		$(".templatesUsed").hide();
		$(".editOptions").append(`<div id="error-babel" style="color:blueviolet; font-family: consolas; font-size:14px; margin-top:8px;"></div>`)
		$(".editButtons").append(`<div style="float:right;font-size:14px;font-weight:bold;margin-top:2px;cursor:pointer;" class="btn btn-success" id="save-babel">环境加载中...</div><div id="wrap-babel" style="positon:absolute;right:0;bottom:0;margin-right:20px;font-size:12px;float:right;color:blueviolet">React同步器:<span id="msg-babel">Babel.js加载中</span></div>`)	
		$.getScript("https://unpkg.com/@babel/standalone@7.20.12/babel.min.js").then(res => {
			$("#msg-babel").html("转码环境已加载");
			$("#save-babel").html("保存并同步转码");
			let pending = false;
			$("#save-babel").click(function() {
				if($(".lang-switch").text() === "JS") {
					changeColor("red");
					return $("#msg-babel").html("你不能在非JSX环境同步...");
				}
				
				if (pending) return;
				pending = true;
				$(this).css("cursor", "no-drop");
				$("#msg-babel").html("同步开始...");
				changeColor("yellow");
				let initCode = editor.session.getDocument().$lines.join("\n");
				let code = "";
				try {
					code = Babel.transform(initCode, {presets: ["react"]}).code;
					code = `/**
* 本文件为${mw.config.values.wgPageName}经过React同步产生的转码文件，带有-babel后缀
* 你应该前往上述文件更改并同步，而不是在本文件中更改
*/\n${code}`;
					$("#error-babel").html("");
				} catch(e){
					$("#msg-babel").html(`<span style="color:darkred">代码出错-Babel转码错误-提交失败</span>`);
					changeColor("red");
					pending = false;
					$(this).css("cursor", "pointer");
					const err = new Error(e.message);
					err.name = "React同步";
					let errStr = err.toString();
					errStr = errStr.replaceAll("<", "&lt;").replaceAll(">", "&gt;")
					errStr = errStr.replace(/&gt; [0-9]+ \|/, `<span style="color:red;font-weight:bold">${/&gt; [0-9]+ \|/.exec(errStr)}`);
					errStr = errStr.replace(/\n +\| +\^/, `${/\n +\| +\^/.exec(errStr)}</span>`);
					errStr = errStr.replaceAll("\n", "<br/>").replaceAll(" ", "&nbsp;");
					errStr = errStr.replace("<span&nbsp;", "<span ");
					$("#error-babel").html(errStr);
					console.log("%c React同步器 %c Babel转码错误", "color: #fff; padding: 5px 0; background: darksalmon;", "padding: 5px 5px 5px 0; background: #e5e5ff; color:darksalmon");
					throw e.message;
				}
				upLoad(mw.config.values.wgPageName, initCode, "React同步：JSX代码(源)[1/2]", 1).then(res => {
					upLoad(`${mw.config.values.wgPageName.slice(0, -3)}-babel.js`, code, "React同步：JS代码(babel转码)[2/2]", 2).then(res => {
						changeColor("green");
						setTimeout(()=> {
							$("#msg-babel").html("同步完成，文件已保存！<br/>(在您没有新的更改之前，离开页面不会弹出警告)");
							pending = false;
							$(this).css("cursor", "pointer");
							$(window).off("beforeunload");
						}, 1500);	
					}, err => {
						pending = false;
						changeColor("red");
						$(this).css("cursor", "pointer");
					});
				}
				, err => {
					pending = false;
					changeColor("red");
					$(this).css("cursor", "pointer");
				});
			});
		}, err => {
			changeColor("red");
			$("#msg-babel").html("转码环境加载失败");
		});
	}

	//初始化js/css/lua提交器
	function initSubmitter(mode) {
		$(".templatesUsed").hide();
		$(".editButtons").append(`<div style="float:right;font-size:14px;font-weight:bold;margin-top:2px;cursor:pointer;" class="btn btn-success" id="save-submitter">提交${mode}并继续编辑</div><div id="wrap-submitter" style="positon:absolute;right:0;bottom:0;margin-right:20px;font-size:12px;float:right;color:blueviolet">${mode}提交器:<span id="msg-submitter">高效调试${mode}</span></div>`)	
		let pending = false;
		$("#save-submitter").click(function() {
			if (pending) return;
			pending = true;
			$(this).css("cursor", "no-drop");
			$("#msg-submitter").html("提交开始...");
			changeColor("yellow");
			let initCode = editor.session.getDocument().$lines.join("\n");
			let code = "";
			upLoad(mw.config.values.wgPageName, initCode, `${mode}提交器：调试${mode}代码`).then(res => {
					changeColor("green");
					setTimeout(()=> {
						$("#msg-submitter").html("提交完成，文件已保存！<br/>(在您没有新的更改之前，离开页面不会弹出警告)");
						pending = false;
						$(this).css("cursor", "pointer");
						$(window).off("beforeunload");
					}, 1500);	
				}, err => {
					pending = false;
					changeColor("red");
					$(this).css("cursor", "pointer");
				}
			);
		});
	}
	
	//初始化widget、模板提交器
	function initWidgetTemplate(mode) {
		$(".editButtons").append(`<div style="float:right;font-size:14px;font-weight:bold;margin-top:2px;cursor:pointer;" class="btn btn-success" id="save-widget">提交${mode}并继续编辑</div><div id="wrap-widget" style="positon:absolute;right:0;bottom:0;margin-right:20px;font-size:12px;float:right;color:blueviolet">${mode}提交器:<span id="msg-widget">高效调试${mode}</span></div>`)	
		let pending = false;
		$("#save-widget").click(function() {
			if (pending) return;
			pending = true;
			let [sl, st] = [0, 0];
		    let textSave = editor.getValue();
			let textPlain = textSave;
			$(this).css("cursor", "no-drop");
			$("#msg-widget").html("提交开始...");
			changeColor("yellow");
			//处理(%%)标记
			if (mode === "模板") {
				const ig = ignorePre(textSave);
				textSave = ig.output;
				map = ig.map;
				let wikitext = getWikiText(textSave);
				for (let wt of wikitext) {
					const plain = wt;
					wt = `<nowiki>${wt}</nowiki>`;
					wt = wt.replaceAll("(%", "</nowiki>").replaceAll("%)", "<nowiki>");
					textSave = textSave.replace(plain, wt);
				}
				st = parseInt(editor.getScrollInfo().top);
				sl = parseInt(editor.getScrollInfo().left);
				textSave = parsePre(textSave, map);
				editor.setValue(textSave);
				setTimeout(()=>$(window).off("beforeunload"), 300);
			}
			//提交代码
			let initCode = "";
			editor.eachLine(line => {initCode += `${line.text}\n`});
			upLoad(mw.config.values.wgPageName, initCode, `${mode}提交器：调试${mode}代码`).then(res => {
					editor.setValue(textPlain);
					setTimeout(()=>$(window).off("beforeunload"), 300);
					editor.scrollTo(sl, st);
					changeColor("green");
					setTimeout(()=> {
						$("#msg-widget").html("提交完成，文件已保存！<br/>(在您没有新的更改之前，离开页面不会弹出警告)");
						pending = false;
						$(this).css("cursor", "pointer");
						$(window).off("beforeunload");
					}, 1500);	
				}, err => {
					pending = false;
					editor.setValue(textPlain);
					setTimeout(()=>$(window).off("beforeunload"), 300);
					editor.scrollTo(sl, st);
					changeColor("red");
					$(this).css("cursor", "pointer");
				}
			);
		});
	}
	
	//改变背景颜色
	function changeColor(color) {
		switch (color) {
			case "init": $(".editOptions").css("background-color", "#eaecf0"); break;
			case "green": $(".editOptions").css("background-color", "#e2ffeb"); break;
			case "yellow": $(".editOptions").css("background-color", "#fffce2"); break;
			case "red": $(".editOptions").css("background-color", "#ffe2e2"); break;
			default: $(".editOptions").css("background-color", "#eaecf0");
		}
	}
	
	
	function upLoad(title, text, summary, step=1) {
		return new Promise((resolve, reject) => {
			let api = new Api();
			api.GET({"action":"query","meta":"tokens","format":"json"}).then(res => {
				const token = res.query.tokens.csrftoken;
				if (token === undefined) {
					$("#msg-babel").html("取得tokens失败")
					$("#msg-submitter").html("取得tokens失败")
					$("#msg-widget").html("取得tokens失败")
					return resolve("fail-token");
				} else {
					api.POST({action:"edit", title: title, text:text, summary: summary, token:token, format:"json"}).then(res => {
						if (res.edit && res.edit.result === "Success") {
							$("#msg-babel").html(`提交 ${title} 成功[${step}/2]`);
							$("#msg-submitter").html(`提交 ${title} 成功`)
							$("#msg-widget").html(`提交 ${title} 成功`)
							return resolve("success");
						} else {
							$("#msg-babel").html(`提交 ${title} 失败`)
							$("#msg-submitter").html(`提交 ${title} 失败`)
							$("#msg-widget").html(`提交 ${title} 失败`)
							return reject("fail-submit");
						}
					}, err => {
						$("#msg-babel").html(`提交 ${title} 失败`)
						$("#msg-submitter").html(`提交 ${title} 失败`)
						$("#msg-widget").html(`提交 ${title} 失败`)
						return reject("fail-submit");
					});
				}
			},err => reject(err));
		});
	
	}

	/* 历史编辑位置相关函数 */
	function isHistoryEdit() {
		try {
			hEdit = JSON.parse(localStorage.getItem("MediaWiki_SmartClick_historyEdit"));
			if (hEdit) {
				console.log(`由于SmartClick设计时未考虑多站点场景，旧版的历史编辑数据没有区分不同站点。
在Version2.0.0后的版本，需要您将旧版历史数据绑定到常用WIKI。
如果这不是你的常用WIKI，请不要绑定数据`);
				let dataBindModal = `<div class="modal" id="databind-modal" tabindex="-1" role="dialog" aria-labelledby="mySmallModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal"><span aria-hidden="true">&times;</span><span class="sr-only">Close</span></button>
        <h4 class="modal-title">SmartClick.js 数据迁移</h4>
      </div>
      <div class="modal-body">
        <p>由于SmartClick设计时未考虑多站点场景，旧版的历史编辑数据没有区分不同站点。<br>在Version2.0.0后的版本，需要您将旧版历史数据绑定到常用WIKI。<br><span style="font-size: 16px; font-weight:bold">如果这不是你使用历史定位功能最多WIKI，请不要绑定数据<br>（请前往相应WIKI绑定</span>）<br>PS.如果迁移出现问题，请联系素子ちゃん_offical</p>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-default" data-dismiss="modal">关闭</button>
        <button type="button" class="btn btn-primary" id="btn-databind">绑定数据</button>
      </div>
    </div>
  </div>
</div>`;
				$("body").append(dataBindModal);
				$("#databind-modal").modal("toggle");
				$("#btn-databind").click(() => {
					let oldData = localStorage.getItem("MediaWiki_SmartClick_historyEdit");
					localStorage.setItem(`MediaWiki_SmartClick_historyEdit_oldData_backup`, oldData);
					localStorage.setItem(`MediaWiki_SmartClick_historyEdit_${mw.config.values.wgGameName}`, oldData);
					alert("绑定数据成功");
					$('#databind-modal').modal('hide');
                	$(".modal-backdrop.fade").hide();
                	localStorage.removeItem("MediaWiki_SmartClick_historyEdit");
				});
			}
		} catch(e) {
			console.log(e);
		}
		
		try {
			hEdit = JSON.parse(localStorage.getItem(`MediaWiki_SmartClick_historyEdit_${mw.config.values.wgGameName}`));
		} catch(e) {
			console.log(e);
		}
		
		let hE = {};
		for(const key in hEdit) {
			if(pageNo === key) {
				hE = hEdit[key];
			}
		}
		if ($.isEmptyObject(hE)) {
			return false;
		} else {
			//绑定历史编辑逻辑
			const handlerKeydownHistory = function(e) {
				if (e.altKey) {
					console.log(hEdit);
					let lineHeight = 20; //默认行高
					let lineTop = 0; //行离顶部的距离
					if (editorType === "CodeMirror") {
						editor.scrollTo(hE.sl, hE.st);
						editor.setCursor(hE.cl, hE.cc);
						editor.focus();
						highlightLine($(".CodeMirror-code").children()[hE.cl]);
					}
					else if (editorType === "Ace") {
						editor.moveCursorTo(hE.cl, hE.cc);
						lineHeight = $(".ace_text-layer .ace_line")[0].clientHeight;
						lineTop = hE.cl * lineHeight;
						if (hE.st - lineTop > (-2 * lineHeight)) {
							editor.session.setScrollTop(lineTop - 2 * lineHeight);
						}
						else if (hE.st - lineTop < (-20 * lineHeight)) {
							editor.session.setScrollTop(lineTop - 20 * lineHeight);
						} 
						else {
							editor.session.setScrollTop(hE.st);
						}
						editor.session.setScrollLeft(hE.sl);
						editor.focus();
						highlightLine($(".ace_active-line")[0]);
						// $(".ace_text-layer .ace_line").each(function(idx, el) {
						// 	let $el = $(el);
						// 	let lineIndex = parseInt($el.css("top").split("px").pop()) / lineHeight;
						// 	if (lineIndex === hE.cursorLine) {
						// 		highlightLine($el);
						// 	}
							// })
							
					}
				}
			}
			const handlerKeyupHistory = function(e) {
				if (e.altKey) {
					e.preventDefault();
					$(document).unbind("keydown", handlerKeydownHistory);
					$(document).unbind("keyup", handlerKeyupHistory);
				}
			}
			$(document).keydown(handlerKeydownHistory);
			$(document).keyup(handlerKeyupHistory);
			
			//编辑器聚焦取消历史编辑功能
			if (editorType !== null) {
				let handlerFocus = function() {
					$(document).unbind("keydown", handlerKeydownHistory);
					$(document).unbind("keyup", handlerKeyupHistory);
					editor.off("focus", handlerFocus);
					$("#alert-area").css("cssText", "height: " + $("#alert-area")[0].clientHeight + "px !important");
					$("#alert-area").css("margin-bottom", "20px");
					$("#alert-edit-history").hide(200);
					setTimeout(function() {
						$("#alert-area").html(basicInform);
						$("#alert-basic-info").hide();
						$("#alert-basic-info").show(200);
					}, 250);
					setTimeout(function() {
						$("#alert-area").css("height", "inherit");	
					}, 450);
				}
				editor.on("focus", handlerFocus);
			}
			
			return true;
		}
	}
	
	//快速定位后高亮行
	function highlightLine(el) {
		let $el = $(el);
		$el.css("background", "rgba(106,255,144,0)");
		for(let i = 0; i < 20; i++) {
			setTimeout(function() {
				if (i < 2) {
					$el.css("background", "rgba(106,255,144," + Math.pow(((i+1)/2), 2.5) + ")");
				} else {
					$el.css("background", "rgba(106,255,144," + Math.pow(((19-i)/16), 0.6) + ")");
				}
				if (i == 19) {
					$el.css("background", "inherit");
				}
			}, i*50+100);
		}
	}
	
	//秒转已经过去的时间
	function getDuration(second) {
	   var duration
	   var days = Math.floor(second / 86400);
	   var hours = Math.floor((second % 86400) / 3600);
	   var minutes = Math.floor(((second % 86400) % 3600) / 60);
	   var seconds = Math.floor(((second % 86400) % 3600) % 60);
	   if(days>0)  duration = days + "天" + hours + "小时" + minutes + "分" + seconds + "秒";
	   else if(hours>0)  duration = hours + "小时" + minutes + "分" + seconds + "秒";
	   else if(minutes>0) duration = minutes + "分" + seconds + "秒";
	   else if(seconds>=0) duration = seconds + "秒";
	   return duration;
	}
}


//绑定editor部分的SmartClick
function bindSmartClick(settings) {
	
	//JS CSS
	$(".cm-mw-template").hover(function(event){
		let $this = $(this);
		let tpName = $this.prev().prev().text();
		if(event.altKey &&  (tpName === "JS" || tpName === "ES6" || tpName === "React" || tpName === "CSS")) {
			tpName = tpName === "ES6"? "JS": tpName;
			tpName = tpName === "React"? "JS": tpName;
			addHighlight([$this, $this.prev(), $this.prev().prev()], "springgreen");
			let linkName = "MediaWiki:" + $this.text() + "." + tpName.toLowerCase();
			addPop([$this], tpName + "文件", linkName);
			addLink([$this], linkName, $this.text(), settings["JS/CSS"], false);
		}
	}, function() {
			let $this = $(this);
			//if(event.altKey) {
				removeHighlight([$this, $this.prev(), $this.prev().prev()]);
				removePop([$this]);
				removeLink([$this]);
			//}
		}
	);
	
	//模板 Data/页面引入
	$(".cm-mw-template-name").hover(function(event){
		let $this = $(this);
		let tpName = $this.text();
		if(event.altKey) {
			addHighlight([$this], "springgreen");
			let linkName = "";
			if (/data:/.test(tpName.toLowerCase())) {
				linkName = tpName.replace(":Data:", "Data:").replace(":data:", "data:");
				addPop([$this], "Data数据", linkName);
				addLink([$this], linkName, tpName, settings["Data数据/页面引入"], false);
			} 
			else if (tpName[0] === ":") {
				linkName = tpName.slice(1);
				addPop([$this], "非模板页面引入", linkName);
				addLink([$this], linkName, tpName, settings["Data数据/页面引入"], false);
			}
			else {
				linkName = "模板:" + tpName;
				addPop([$this], "Wiki模板", linkName);
				addLink([$this], linkName, tpName, settings["模板"], false);
			}
		}
	}, function() {
			let $this = $(this);
			//if(event.altKey) {
				removeHighlight([$this]);
				removePop([$this]);
				removeLink([$this]);
			//}
		}
	);
		
	//链接or文件
	$(".cm-mw-link-pagename").hover(function(event){
		let $this = $(this);
		let tpName = $this.text();
		if(event.altKey) {
			addHighlight([$this], "springgreen");
			let linkName = tpName;
			// if (/^(?:http(s)?:\/\/)?[\w.-]+(?:\.[\w\.-]+)+[\w\-\._~:/?#[\]@!\$&'\*\+,;=.]+$/.test(linkName)) {
			// 	addPop([$this], "站外链接", linkName);
			// 	addLink([$this], linkName, tpName, false);
			// } else {
			if (/file:/.test(linkName.toLowerCase()) || /文件:/.test(linkName)) {
				addPop([$this], "Wiki文件", linkName);
				addLink([$this], linkName, tpName, false, false);
				queryFile([$this], linkName);
			} else {
				addPop([$this], "站内链接", linkName);
				addLink([$this], linkName, tpName, false, false);
			}
			//}
		}
	}, function() {
			let $this = $(this);
			//if(event.altKey) {
				removeHighlight([$this]);
				removePop([$this]);
				removeLink([$this]);
			//}
		}
	);
	
	//站外链接
	$(".cm-mw-extlink").hover(function(event){
		let $this = $(this);
		let tpName = $this.text();
		if(event.altKey) {
			addHighlight([$this, $this.prev()], "springgreen");
			let linkName = tpName;
			addPop([$this], "站外链接", "https://" + linkName);
			addLink([$this], linkName, tpName, false, true);
		}
	}, function() {
			let $this = $(this);
			//if(event.altKey) {
				removeHighlight([$this, $this.prev()]);
				removePop([$this]);
				removeLink([$this]);
			//}
		}
	);
	
	//#invoke:数据库 /#widget:组件
	$(".cm-mw-parserfunction").hover(function(event){
		let $this = $(this);
		let tpName = $this.prev().prev().text();
		if(event.altKey && tpName === "#invoke") {
			addHighlight([$this, $this.prev(), $this.prev().prev()], "springgreen");
			let linkName = "模块:" + $this.text();
			addPop([$this], "#invoke:模块", linkName);
			addLink([$this], linkName, tpName, settings["数据库"], false);
		}
		else if (event.altKey && tpName.toLowerCase() === "#widget") {
			addHighlight([$this, $this.prev(), $this.prev().prev()], "springgreen");
			let linkName = "Widget:" + $this.text();
			addPop([$this], "#widget:组件", linkName);
			addLink([$this], linkName, tpName, settings["Widget组件"], false);
		}
	}, function() {
			let $this = $(this);
			//if(event.altKey) {
				removeHighlight([$this, $this.prev(),$this.prev().prev()]);
				removePop([$this]);
				removeLink([$this]);
			//}
		}
	);
}


function addHighlight(elList, color) {
	for (let idx in elList) {
		let $el = elList[idx];
		$el.css("background", color);
	}
}

function removeHighlight(elList) {
	for (let idx in elList) {
		let $el = elList[idx];
		$el.css("background", "inherit");
	}
}

function addPop(elList, popTitle, popText) {
	for (let idx in elList) {
		let $el = elList[idx];
		$el.attr("title", popTitle);
		$el.attr("data-container", "body");
		$el.attr("data-toggle", "popover");
		$el.attr("data-placement", "bottom");
		$el.attr("data-trigger", "manual");
		$el.attr("data-content", popText);
		$el.popover("show");
	}
}

function removePop(elList) {
	for (let idx in elList) {
		let $el = elList[idx];
		$el.popover("destroy");
	}
}

function addLink(elList, linkName, initName, edit, extLink) {
	let linkHead = "https://wiki.biligame.com/" + apiUrl + "/index.php?title=";
	let linkTail = "&action=edit";
	for (let idx in elList) {
		let $el = elList[idx];
		$el.css("cursor","url(" + cursorUrl + "),pointer");
		$el.unbind("click").bind("click", function() {
			let $this = $(this);
			window.open((extLink? "https://": linkHead) + linkName + (edit?linkTail: ""));
			removeHighlight([$this, $this.prev(), $this.prev().prev()]);
			removePop([$this]);
			removeLink([$this]);
		});	
		
		// $el.html("<a href=\"javascript:；\" target=\"_blank\" class=\"tempA\">" + initName +  "</a>");
		// $(".tempA").click(function() {
		// 	window.open(linkHead + linkName +linkTail);
		// })
	}
}

function removeLink(elList) {
	for (let idx in elList) {
		let $el = elList[idx];
		$el.css("cursor","inherit");
		$el.unbind("click");
		// $el.html($el.children().text());
	}
}

//通过data-cache限制api访问过量的问题
function queryFile(elList, linkName) {
	for (let idx in elList) {
		let $el = elList[idx];
		let callback = {
			"success": function(result) {
				let regex = new RegExp (linkName);
				if (result.length !== 0 && regex.test($(".popover-content").text())) {
					$el.attr("data-cache", encodeURIComponent(result));
					$(".popover-content").html(result);
					removeLink([$el]);
					let tpName = linkName;
					let fileName = linkName.split("file:").pop().split("File:").pop().split("文件:").pop();
					regex = new RegExp(linkName.toLowerCase());
					if (regex.test(result.toLowerCase())) {
						addLink([$el], "特殊:上传文件&wpUploadDescription=通过SmartClick创建&wpDestFile=" + fileName, tpName, false, false);
					} else {
						addLink([$el], linkName, tpName, false, false);
					}
				}
			},
			"fail": function(error) {
				$(".popover-content").html(linkName + "（解析失败）");
				console.log(error);
			}	
		};
		
		if ($el.data("cache") !== undefined) {
			let cache = decodeURIComponent($el.attr("data-cache"));
			let regex = new RegExp (linkName);
			if (regex.test($(".popover-content").text())) {
				$(".popover-content").html(cache);
			}
			let fileName = linkName.split("file:").pop().split("File:").pop().split("文件:").pop();
			let tpName = linkName;
			regex = new RegExp(fileName.toLowerCase())
			if (regex.test(cache.toLowerCase())) {
				removeLink([$el]);
				addLink([$el], "特殊:上传文件&wpUploadDescription=通过SmartClick创建&wpDestFile=" + fileName, tpName, false, false);
			}
		} else {
			wikiParser("[[" + linkName + "]]", callback);
		}
	}
}


//解析wiki文本函数
//参考自烟雨江湖wiki：https://wiki.biligame.com/yanyu/index.php?title=%E7%83%9F%E9%9B%A8%E6%B1%9F%E6%B9%96:Tooltip%E6%BC%94%E7%A4%BA
//@param:
//    wikitext: String 需要解析的wiki文本
//    callback: Object 解析完成后调用的函数组，包含success与fail，格式为{"success": function(result) { //成功函数 }, "fail": function(error) { //失败函数 }}
//        -success: function 解析成功后执行的函数，需包含一个参数接收解析结果
//        -fail: function 解析失败后执行的函数，需包含一个参数接收错误报告
function wikiParser(wikitext, callback) {
	// 文档：https://wiki.biligame.com/wiki/api.php?action=help&modules=parse
	return $.get("/" + apiUrl + "/api.php",{
		action: "parse", // 解析
		format: "json", // 返回内容的格式
		disablelimitreport: true, // 不返回使用内存、时间信息
		prop: "text", // 返回解析后的文本
		smaxage: 5,
		maxage: 5,
		contentmodel: "wikitext", // 内容模型
		text: wikitext, // 待解析文本
		_: mw.config.get('debug') ? Date.now() : null // 调试时不使用缓存
	}).then(function(result){
		if (result && result.parse && result.parse.text){
			callback.success(result.parse.text['*']);
		}
		else{
			throw result;
		}
	})["catch"](function(error) { callback.fail(error);});
}

function wikiParserPro(wikitext) {
	// 文档：https://wiki.biligame.com/wiki/api.php?action=help&modules=parse
	return new Promise((resolve, reject) => {
			$.get("/" + apiUrl + "/api.php",{
			action: "parse", // 解析
			format: "json", // 返回内容的格式
			disablelimitreport: true, // 不返回使用内存、时间信息
			prop: "text", // 返回解析后的文本
			contentmodel: "wikitext", // 内容模型
			text: wikitext, // 待解析文本
			_: mw.config.get('debug') ? Date.now() : null // 调试时不使用缓存
		}).then(function(result){
			if (result && result.parse && result.parse.text){
				return resolve(result.parse.text['*']);
			}
			else{
				throw reject(result);
			}
		}, err => reject(err));
	});
}