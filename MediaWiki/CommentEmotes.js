// <pre>
/*
		@author 鬼影233&GPT5
		@description 评论区表情包，需要对应CSS
		@lincense CC-BY-NC-SA 4.0
*/
(() => {
    if (!document.body.getElementsByClassName("comment-thread")) return;

    // --------- 配置：要读取的 wiki 页面（把页面名换成你站点上实际的 JSON 页面） ---------
    const WIKI_JSON_PAGE = "MediaWiki:EmotesData.json"; //
    const CACHE_KEY = "commentEmotesJSON"; // 
    const CACHE_TTL = 1000 * 60 * 60 * 24; // 缓存 24 小时（毫秒），可按需调整

    // --------- 内置回退数据（可选） ---------
    const fallbackEmoteImgs = {
    };

    // --------- 工具：从 localStorage 读取/写入缓存 ---------
    const readCache = () => {
        try {
            const raw = localStorage.getItem(CACHE_KEY);
            if (!raw) return null;
            const obj = JSON.parse(raw);
            if (Date.now() - obj.t > CACHE_TTL) {
                localStorage.removeItem(CACHE_KEY);
                return null;
            }
            return obj.data;
        } catch (e) {
            return null;
        }
    };
    const writeCache = (data) => {
        try {
            localStorage.setItem(CACHE_KEY, JSON.stringify({ t: Date.now(), data }));
        } catch (e) {
            // ignore
        }
    };

    // --------- 主流程：尝试用 MediaWiki API 拉取 JSON（使用 mw.Api，如果在 gadget 上会有 mw） ---------
    const fetchEmoteJsonViaApi = () => {
        return new Promise((resolve, reject) => {
            try {
                if (typeof mw !== "undefined" && mw && mw.loader) {
                    mw.loader.using("mediawiki.api").then(() => {
                        const api = new mw.Api();
                        api.get({
                            action: "query",
                            prop: "revisions",
                            titles: WIKI_JSON_PAGE,
                            rvprop: "content",
                            rvslots: "main",
                            format: "json"
                        }).done((data) => {
                            try {
                                const pages = data.query && data.query.pages;
                                const pageId = Object.keys(pages)[0];
                                const page = pages[pageId];
                                if (page && page.revisions && page.revisions[0]) {
                                    const content = page.revisions[0].slots.main["*"] || "";
                                    // 页面里可能有 <pre> 或注释之类，尝试抽取首个 JSON 对象
                                    let jsonText = content.trim();
                                    // 如果页面是以 <pre> 包裹，去掉 <pre> 标签
                                    jsonText = jsonText.replace(/^<pre[^>]*>/i, "").replace(/<\/pre>$/i, "").trim();
                                    // 解析
                                    const parsed = JSON.parse(jsonText);
                                    writeCache(parsed);
                                    resolve(parsed);
                                } else {
                                    reject(new Error("no revision content"));
                                }
                            } catch (err) {
                                reject(err);
                            }
                        }).fail(err => reject(err));
                    }).catch(err => reject(err));
                } else {
                    reject(new Error("mw is not available"));
                }
            } catch (e) {
                reject(e);
            }
        });
    };

    // --------- 如果需要，也可以用 fetch 直接请求 api.php（同域情况下可行） ---------
    const fetchEmoteJsonViaFetch = () => {
        return new Promise((resolve, reject) => {
            try {
                const apiUrl = "/w/api.php?action=query&prop=revisions&titles=" + encodeURIComponent(WIKI_JSON_PAGE) + "&rvprop=content&rvslots=main&format=json&origin=*";
                fetch(apiUrl, { credentials: "same-origin" }).then(r => r.json()).then(data => {
                    try {
                        const pages = data.query && data.query.pages;
                        const pageId = Object.keys(pages)[0];
                        const page = pages[pageId];
                        if (page && page.revisions && page.revisions[0]) {
                            let content = page.revisions[0].slots.main["*"] || "";
                            content = content.replace(/^<pre[^>]*>/i, "").replace(/<\/pre>$/i, "").trim();
                            const parsed = JSON.parse(content);
                            writeCache(parsed);
                            resolve(parsed);
                        } else {
                            reject(new Error("no revision content"));
                        }
                    } catch (err) {
                        reject(err);
                    }
                }).catch(err => reject(err));
            } catch (e) {
                reject(e);
            }
        });
    };

    // --------- 初始化表情面板（把你原来基于 emoteImgs 的 DOM 构造代码放在这里） ---------
    const initEmotesWithData = (emoteImgs) => {
        const text2emote = () => {
    		document.body
        		.querySelectorAll(".comment-text, .comment-text-mobile, .comment-text2")
        		.forEach(e => {
            		e.innerHTML = e.innerHTML.replace(
            			/(\[\\表情-(.+?)\s(.*?)\])/g,
                		`<img class="comment-emote" src="https://patchwiki.biligame.com/images/klbq/$2" title="$3" alt="$1" loading="lazy" decoding="async">`
            		);
        		});
		};
        text2emote();
        const observer = new MutationObserver(text2emote);
        const commentContainer = document.body.getElementsByClassName("comment-container")[0];
        if (commentContainer) {
            observer.observe(commentContainer, { childList: true });
        }

        const creatEmoteExt = (replybox) => {
            const extensions = document.createElement("div");
            extensions.classList.add("comment-extensions");
            const emotesButton = document.createElement("i");
            emotesButton.classList.add("comment-emotes-button");
            emotesButton.title = "表情包";
            emotesButton.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" height="1em" viewBox="0 0 512 512" fill="currentColor"><path d="M464 256A208 208 0 1 0 48 256a208 208 0 1 0 416 0zM0 256a256 256 0 1 1 512 0A256 256 0 1 1 0 256zm177.6 62.1C192.8 334.5 218.8 352 256 352s63.2-17.5 78.4-33.9c9-9.7 24.2-10.4 33.9-1.4s10.4 24.2 1.4 33.9c-22 23.8-60 49.4-113.6 49.4s-91.7-25.5-113.6-49.4c-9-9.7-8.4-24.9 1.4-33.9s24.9-8.4 33.9 1.4zM144.4 208a32 32 0 1 1 64 0 32 32 0 1 1 -64 0zm192-32a32 32 0 1 1 0 64 32 32 0 1 1 0-64z"/></svg>`;
            const emotesBox = document.createElement("div");
            emotesBox.classList.add("comment-emotes-box");
            emotesBox.style.display = "none";
            const emotesOptions = document.createElement("div");
            emotesOptions.classList.add("comment-emotes-options");
            for (const [name, imgs] of Object.entries(emoteImgs)) {
                const emotesOption = document.createElement("img");
                emotesOption.classList.add(
                    "comment-emotes-option",
                    `comment-emotes-option-${name}`
                );
                emotesOption.title = name;
                emotesOption.alt = name;
                emotesOption.loading = "lazy";
                emotesOption.decoding = "async";
                emotesOption.onclick = () => {
                    [...document.body.getElementsByClassName("comment-emotes-option-active")].forEach(e => e.classList.remove("comment-emotes-option-active"));
                    [...document.body.getElementsByClassName(`comment-emotes-option-${name}`)].forEach(e => e.classList.add("comment-emotes-option-active"));
                    [...document.body.getElementsByClassName("comment-emotes-active")].forEach(e => { e.classList.remove("comment-emotes-active"); });
                    [...document.body.getElementsByClassName(`comment-emotes-${name}`)].forEach(e => { e.classList.add("comment-emotes-active"); });
                };
                emotesOption.src = `https://patchwiki.biligame.com/images/klbq/${Object.keys(imgs)[0]}`;
                emotesOptions.appendChild(emotesOption);

                const emotes = document.createElement("div");
                emotes.classList.add("comment-emotes", `comment-emotes-${name}`);
                for (const [src, title] of Object.entries(imgs)) {
                    const emote = document.createElement("img");
                    emote.classList.add("comment-emote");
                    emote.title = title;
                    emote.alt = `[\\表情-${src} ${title}]`;
                    emote.loading = "lazy";
                    emote.decoding = "async";
                    emote.onclick = () => {
                        const textarea = replybox.getElementsByTagName("textarea")[0];
                        textarea.value += `[\\表情-${src} ${title}]`;
                        textarea.focus();
                    };
                    emotes.appendChild(emote);
                    emote.src = `https://patchwiki.biligame.com/images/klbq/${src}`;
                }
                emotesBox.appendChild(emotes);
            }
            // activate first option by default if exists
            const firstOption = emotesOptions.getElementsByClassName("comment-emotes-option")[0];
            if (firstOption) firstOption.classList.add("comment-emotes-option-active");
            const firstEmotes = emotesBox.getElementsByClassName("comment-emotes")[0];
            if (firstEmotes) firstEmotes.classList.add("comment-emotes-active");
            emotesBox.appendChild(emotesOptions);
            emotesButton.getElementsByTagName("svg")[0].onclick = () =>
                (emotesBox.style.display = emotesBox.style.display === "none" ? "block" : "none");
            document.body.onclick = e => {
                if (
                    emotesBox.style.display === "block" &&
                    e.target !== emotesButton &&
                    !emotesButton.contains(e.target) &&
                    e.target !== emotesBox &&
                    !emotesBox.contains(e.target)
                ) emotesBox.style.display = "none";
            };
            emotesButton.appendChild(emotesBox);
            extensions.appendChild(emotesButton);
            return extensions;
        };

        // mount into page (跟原脚本逻辑一致)
        if (window.navigator.userAgent.indexOf("BiliApp") !== -1) {
            const placeholder = document.createElement("div");
            placeholder.id = "comment-extensions-placeholder";
            document.body.querySelector(".bui-reply-table > a").outerHTML += placeholder.outerHTML;
            document.getElementById("comment-extensions-placeholder").replaceWith(
                creatEmoteExt(document.body.getElementsByClassName("bui-reply-box")[0])
            );
            document.body.getElementsByClassName("comment-extensions")[0].classList.add("comment-extensions-app");
        } else {
            const replybox = document.body.getElementsByClassName("comment-replybox")[0];
            if (replybox) {
                replybox.appendChild(creatEmoteExt(replybox));
            }
            document.body.getElementsByClassName("comment-reply").forEach(e => {
                e.onclick = () => {
                    const rb = e.parentElement.parentElement.parentElement.parentElement.getElementsByClassName("comment-replybox")[0];
                    if (!rb) return;
                    rb.appendChild(creatEmoteExt(rb));
                };
            });
        }
    }; // end initEmotesWithData

    // --------- 启动：优先使用缓存，然后尝试 API，再尝试 fetch，最后使用回退数据 ---------
    (async () => {
        const cached = readCache();
        if (cached) {
            try { initEmotesWithData(cached); return; } catch (e) { /* fallthrough to reload */ }
        }
        try {
            const data = await fetchEmoteJsonViaApi();
            initEmotesWithData(data);
            return;
        } catch (e1) {
            try {
                const data = await fetchEmoteJsonViaFetch();
                initEmotesWithData(data);
                return;
            } catch (e2) {
                // 回退
                initEmotesWithData(fallbackEmoteImgs);
                return;
            }
        }
    })();

})();
// </pre>