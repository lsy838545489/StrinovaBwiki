"use strict";

(window.RLQ = window.RLQ || []).push(function () {
	function initWikiSidebar() {
		if (document.getElementById("wiki-sidebar")) return;

		var wgScriptPath = mw.config.get("wgScriptPath") || "";
		var wgScript = mw.config.get("wgScript") || wgScriptPath + "/index.php";
		var currentPage = normalizeForCompare(mw.config.get("wgPageName") || "");

		// 缓存配置常量
		var CACHE_KEY = "wiki-sidebar-content-v1";

		function normalizeForCompare(title) {
			var base = String(title || "").split("#")[0];
			if (window.mw && mw.Title && typeof mw.Title.newFromText === "function") {
				try {
					var t = mw.Title.newFromText(base);
					if (t) return t.getPrefixedText().replace(/_/g, " ").toLowerCase();
				} catch (e) {}
			}
			var trimmed = base.trim().replace(/_/g, " ");
			if (!trimmed) return "";
			return trimmed.toLowerCase();
		}

		function getUrl(pageName) {
			var trimmed = String(pageName || "").trim();
			if (!trimmed) return "#";
			if (trimmed.charAt(0) === "#") return trimmed;
			if (/^(javascript|data|vbscript):/i.test(trimmed)) return "#";
			if (/^\/\//.test(trimmed)) return "#";
			if (/^https?:\/\//i.test(trimmed)) {
				if (/[<>"'\s]/.test(trimmed)) return "#";
				return trimmed;
			}
			if (window.mw && mw.util && typeof mw.util.getUrl === "function") {
				return mw.util.getUrl(trimmed);
			}
			var articlePath =
				mw.config.get("wgArticlePath") || wgScriptPath + "/index.php?title=$1";
			var encoded = encodeURIComponent(trimmed.replace(/ /g, "_"))
				.replace(/%3A/g, ":")
				.replace(/%2F/g, "/");
			return articlePath.replace("$1", encoded);
		}

		function getSidebarState() {
			try {
				return window.localStorage.getItem("wiki-sidebar-state");
			} catch (e) {
				return null;
			}
		}

		function setSidebarState(value) {
			try {
				window.localStorage.setItem("wiki-sidebar-state", value);
			} catch (e) {}
		}

		function isMobile() {
			return (window.innerWidth || document.body.clientWidth) < 992;
		}

		var resizeTimer = null;
		var lastWidth = window.innerWidth || document.body.clientWidth;

		function createHeading(label, target, isActive) {
			var node;
			if (target) {
				node = document.createElement("a");
				node.className =
					"wiki-sidebar__heading wiki-sidebar__heading--link" +
					(isActive ? " wiki-sidebar__heading--active" : "");
				node.href = getUrl(target);
				node.textContent = label;
			} else {
				node = document.createElement("div");
				node.className = "wiki-sidebar__heading";
				node.textContent = label;
			}
			return node;
		}

		function createSubheading(label, target, isActive, isCollapsible) {
			var node;
			if (isCollapsible) {
				node = document.createElement("button");
				node.type = "button";
				node.className =
					"wiki-sidebar__subheading wiki-sidebar__subheading--collapsible" +
					(isActive ? " wiki-sidebar__subheading--active" : "");
				node.setAttribute("aria-expanded", "false");
				node.textContent = label;
			} else if (target) {
				node = document.createElement("a");
				node.className =
					"wiki-sidebar__subheading wiki-sidebar__subheading--link" +
					(isActive ? " wiki-sidebar__subheading--active" : "");
				node.href = getUrl(target);
				node.textContent = label;
			} else {
				node = document.createElement("div");
				node.className = "wiki-sidebar__subheading";
				node.textContent = label;
			}
			return node;
		}

		function createItem(label, target, isActive, level) {
			var a = document.createElement("a");
			var className = "wiki-sidebar__item";
			className +=
				level === 3
					? " wiki-sidebar__item--level3"
					: " wiki-sidebar__item--level2";
			if (isActive) className += " wiki-sidebar__item--active";
			a.className = className;
			a.href = getUrl(target || label);
			a.setAttribute("aria-label", label);

			var dot = document.createElement("span");
			dot.className =
				level === 3
					? "wiki-sidebar__dot wiki-sidebar__dot--level3"
					: "wiki-sidebar__dot";
			a.appendChild(dot);
			a.appendChild(document.createTextNode(label));
			return a;
		}

		function parseSidebarLine(line) {
			var match = line.match(/^(\*{1,3})\s*(.*)$/);
			if (!match) return null;

			var level = match[1].length;
			var rest = (match[2] || "").trim();
			if (!rest) return null;

			var pipeIndex = rest.indexOf("|");
			var target, label, hasPipe;
			if (pipeIndex >= 0) {
				target = rest.substring(0, pipeIndex).trim();
				label = rest.substring(pipeIndex + 1).trim();
				hasPipe = true;
			} else {
				target = rest;
				label = rest;
				hasPipe = false;
			}
			return { level: level, target: target, label: label, hasPipe: hasPipe };
		}

		// 将原本的构建 DOM 逻辑封装为一个单独的函数，方便直读缓存或 API 请求后调用
		function renderSidebar(content) {
			var lines = content.split("\n");

			var sidebar = document.createElement("div");
			sidebar.id = "wiki-sidebar";
			sidebar.className = "wiki-sidebar";

			if (isMobile()) {
				sidebar.classList.add("wiki-sidebar--hidden");
			}

			var toggleBtn = document.createElement("div");
			toggleBtn.id = "sb-toggle";
			toggleBtn.className = "wiki-sidebar__toggle";
			toggleBtn.setAttribute("role", "button");
			toggleBtn.setAttribute("tabindex", "0");
			toggleBtn.setAttribute("aria-label", "切换侧边栏");
			toggleBtn.setAttribute("aria-expanded", "false");

			if (!isMobile()) {
				if (getSidebarState() === "collapsed") {
					sidebar.classList.add("wiki-sidebar--hidden");
				}
				toggleBtn.setAttribute(
					"aria-expanded",
					String(!sidebar.classList.contains("wiki-sidebar--hidden"))
				);
			}

			var inner = document.createElement("div");
			inner.className = "wiki-sidebar__inner";

			var searchWrap = document.createElement("div");
			searchWrap.className = "wiki-sidebar__search-wrap";

			var form = document.createElement("form");
			form.action = wgScript;
			form.id = "sb-searchform";
			form.className = "wiki-sidebar__search-form";
			form.method = "get";

			var hiddenTitle = document.createElement("input");
			hiddenTitle.type = "hidden";
			hiddenTitle.name = "title";
			hiddenTitle.value = "Special:Search";

			var searchInput = document.createElement("input");
			searchInput.type = "search";
			searchInput.name = "search";
			searchInput.placeholder = "输入关键词搜索...";
			searchInput.id = "sb-search-input";
			searchInput.className = "wiki-sidebar__search-input";
			searchInput.setAttribute("autocomplete", "off");
			searchInput.setAttribute("title", "在全站搜索 [f]");
			searchInput.setAttribute("accesskey", "f");
			searchInput.setAttribute("aria-label", "搜索关键词");

			var searchBtn = document.createElement("button");
			searchBtn.type = "submit";
			searchBtn.id = "sb-search-btn";
			searchBtn.className = "wiki-sidebar__search-btn";
			searchBtn.textContent = "GO";

			form.appendChild(hiddenTitle);
			form.appendChild(searchInput);
			form.appendChild(searchBtn);
			searchWrap.appendChild(form);

			var parsedItems = [];
			for (var i = 0; i < lines.length; i++) {
				var rawLine = lines[i];
				if (!rawLine) continue;
				var line = rawLine.trim();
				if (!line) continue;
				var item = parseSidebarLine(line);
				if (item) parsedItems.push(item);
			}

			// [优化点2] 采用 DocumentFragment 提升内层菜单结构的渲染性能
			var listFragment = document.createDocumentFragment();
			var currentLevel1Group = null;
			var currentLevel2Group = null;
			var currentSubgroupWrapper = null;

			function ensureLevel1Group() {
				if (!currentLevel1Group) {
					currentLevel1Group = document.createElement("div");
					currentLevel1Group.className =
						"wiki-sidebar__group wiki-sidebar__group--level1";
					listFragment.appendChild(currentLevel1Group); // 挂载到片段上
				}
				return currentLevel1Group;
			}

			function beginLevel2Subgroup(item, isActive, isCollapsible) {
				ensureLevel1Group();

				var subgroupWrapper = document.createElement("div");
				subgroupWrapper.className = "wiki-sidebar__subgroup";

				if (isCollapsible) {
					subgroupWrapper.classList.add("wiki-sidebar__subgroup--collapsible");
					subgroupWrapper.classList.add("wiki-sidebar__subgroup--collapsed");
				}

				var subheadingNode = createSubheading(
					item.label,
					item.hasPipe ? item.target : "",
					item.hasPipe && isActive,
					isCollapsible
				);

				currentLevel2Group = document.createElement("div");
				currentLevel2Group.className =
					"wiki-sidebar__group wiki-sidebar__group--level2";

				subgroupWrapper.appendChild(subheadingNode);
				subgroupWrapper.appendChild(currentLevel2Group);
				currentLevel1Group.appendChild(subgroupWrapper);
				currentSubgroupWrapper = subgroupWrapper;

				if (isCollapsible && isActive) {
					subgroupWrapper.classList.remove("wiki-sidebar__subgroup--collapsed");
					subheadingNode.setAttribute("aria-expanded", "true");
				}
			}

			function beginImplicitLevel2Group() {
				ensureLevel1Group();

				var subgroupWrapper = document.createElement("div");
				subgroupWrapper.className =
					"wiki-sidebar__subgroup wiki-sidebar__subgroup--implicit";

				currentLevel2Group = document.createElement("div");
				currentLevel2Group.className =
					"wiki-sidebar__group wiki-sidebar__group--level2";

				subgroupWrapper.appendChild(currentLevel2Group);
				currentLevel1Group.appendChild(subgroupWrapper);
				currentSubgroupWrapper = subgroupWrapper;
			}

			for (var j = 0; j < parsedItems.length; j++) {
				var pItem = parsedItems[j];
				var nextItem = parsedItems[j + 1] || null;

				var compareTarget = pItem.target || pItem.label;
				var normalizedLink = normalizeForCompare(compareTarget);
				var isActive = !!(normalizedLink && currentPage === normalizedLink);

				if (pItem.level === 1) {
					currentLevel1Group = null;
					currentLevel2Group = null;
					currentSubgroupWrapper = null;

					var headingTarget = pItem.hasPipe ? pItem.target : "";
					var headingActive = pItem.hasPipe && isActive;
					listFragment.appendChild(
						createHeading(pItem.label, headingTarget, headingActive)
					);
				} else if (pItem.level === 2) {
					ensureLevel1Group();

					var hasLevel3Children = !!(nextItem && nextItem.level === 3);

					if (hasLevel3Children) {
						currentLevel2Group = null;
						beginLevel2Subgroup(pItem, isActive, true);
					} else {
						currentLevel2Group = null;
						currentSubgroupWrapper = null;
						currentLevel1Group.appendChild(
							createItem(pItem.label, pItem.target, isActive, 2)
						);
					}
				} else if (pItem.level === 3) {
					if (!currentLevel2Group) {
						beginImplicitLevel2Group();
					}
					currentLevel2Group.appendChild(
						createItem(pItem.label, pItem.target, isActive, 3)
					);

					if (isActive && currentSubgroupWrapper) {
						currentSubgroupWrapper.classList.remove(
							"wiki-sidebar__subgroup--collapsed"
						);
						var heading = currentSubgroupWrapper.querySelector(
							".wiki-sidebar__subheading"
						);
						if (heading) heading.setAttribute("aria-expanded", "true");
					}
				}
			}

			inner.appendChild(listFragment);

			// 手风琴展开/收起的折叠动画 (Height Transition)
			inner.addEventListener("click", function (e) {
				var target = e.target;
				while (target && target !== inner) {
					if (
						target.classList &&
						target.classList.contains("wiki-sidebar__subheading--collapsible")
					) {
						var subgroup = target.parentElement;
						if (subgroup) {
							var lvl2Group = subgroup.querySelector(
								".wiki-sidebar__group--level2"
							);
							var isCollapsed = subgroup.classList.contains(
								"wiki-sidebar__subgroup--collapsed"
							);

							if (lvl2Group && lvl2Group._transitionHandler) {
								lvl2Group.removeEventListener(
									"transitionend",
									lvl2Group._transitionHandler
								);
								lvl2Group._transitionHandler = null;
								lvl2Group.style.transition = "none";
								void lvl2Group.offsetHeight;
								lvl2Group.style.transition = "";
							}

							if (isCollapsed) {
								// ================== 展开逻辑 (Expand) ==================
								subgroup.classList.remove("wiki-sidebar__subgroup--collapsed");
								target.setAttribute("aria-expanded", "true");

								if (lvl2Group) {
									lvl2Group.style.maxHeight = "0px";
									void lvl2Group.offsetWidth;
									lvl2Group.style.maxHeight = lvl2Group.scrollHeight + "px";

									var expandHandler = function handler(event) {
										if (
											event.target !== lvl2Group ||
											event.propertyName !== "max-height"
										)
											return;
										lvl2Group.removeEventListener("transitionend", handler);
										lvl2Group._transitionHandler = null;
										if (
											!subgroup.classList.contains(
												"wiki-sidebar__subgroup--collapsed"
											)
										) {
											lvl2Group.style.maxHeight = "none";
										}
									};

									lvl2Group._transitionHandler = expandHandler;
									lvl2Group.addEventListener("transitionend", expandHandler);
								}
							} else {
								// ================== 收起逻辑 (Collapse) ==================
								subgroup.classList.add("wiki-sidebar__subgroup--collapsed");
								target.setAttribute("aria-expanded", "false");

								if (lvl2Group) {
									lvl2Group.style.maxHeight = lvl2Group.scrollHeight + "px";
									void lvl2Group.offsetWidth;
									lvl2Group.style.maxHeight = "0px";

									var collapseHandler = function handler(event) {
										if (
											event.target !== lvl2Group ||
											event.propertyName !== "max-height"
										)
											return;
										lvl2Group.removeEventListener("transitionend", handler);
										lvl2Group._transitionHandler = null;
									};
									lvl2Group._transitionHandler = collapseHandler;
									lvl2Group.addEventListener("transitionend", collapseHandler);
								}
							}
						}
						break;
					}
					target = target.parentElement;
				}
			});

			sidebar.appendChild(toggleBtn);
			sidebar.appendChild(searchWrap);
			sidebar.appendChild(inner);
			document.body.appendChild(sidebar);

			// [优化点3] 自动滚动吸附到当前激活的菜单项
			(function () {
				function pickBestActiveElement(root) {
					var candidates = root.querySelectorAll(
						".wiki-sidebar__item--active, .wiki-sidebar__subheading--active, .wiki-sidebar__heading--active"
					);
					if (!candidates.length) return null;

					var best = null;
					var bestScore = -1;

					for (var i = 0; i < candidates.length; i++) {
						var el = candidates[i];
						var score = 0;

						if (el.classList.contains("wiki-sidebar__item--level3"))
							score = 300;
						else if (el.classList.contains("wiki-sidebar__item--level2"))
							score = 200;
						else if (
							el.classList.contains("wiki-sidebar__subheading--collapsible")
						)
							score = 150;
						else if (el.classList.contains("wiki-sidebar__subheading--link"))
							score = 140;
						else if (el.classList.contains("wiki-sidebar__heading--link"))
							score = 100;
						else if (el.classList.contains("wiki-sidebar__heading")) score = 90;

						if (score > bestScore) {
							bestScore = score;
							best = el;
						}
					}
					return best;
				}

				var activeEl = pickBestActiveElement(sidebar);
				if (!activeEl) return;

				function scrollToActive() {
					requestAnimationFrame(function () {
						if (!activeEl.isConnected) return;
						activeEl.scrollIntoView({
							behavior: "smooth",
							block: "center",
						});
					});
				}

				if (!sidebar.classList.contains("wiki-sidebar--hidden")) {
					setTimeout(scrollToActive, 100);
				} else {
					var observer = new MutationObserver(function (mutations) {
						for (var i = 0; i < mutations.length; i++) {
							if (
								mutations[i].type === "attributes" &&
								mutations[i].attributeName === "class" &&
								!sidebar.classList.contains("wiki-sidebar--hidden")
							) {
								setTimeout(scrollToActive, 350);
								observer.disconnect();
								break;
							}
						}
					});
					observer.observe(sidebar, {
						attributes: true,
						attributeFilter: ["class"],
					});
				}
			})();

			document.body.classList.add("has-wiki-sidebar");

			function toggleSidebar(force, saveState) {
				if (saveState === undefined) saveState = true;
				var isHidden;
				if (typeof force === "boolean") {
					if (force) {
						sidebar.classList.add("wiki-sidebar--hidden");
					} else {
						sidebar.classList.remove("wiki-sidebar--hidden");
					}
					isHidden = force;
				} else {
					isHidden = sidebar.classList.toggle("wiki-sidebar--hidden");
				}
				toggleBtn.setAttribute("aria-expanded", String(!isHidden));

				if (saveState && !isMobile()) {
					setSidebarState(isHidden ? "collapsed" : "expanded");
				}
			}

			toggleBtn.addEventListener("click", function () {
				toggleSidebar();
			});

			toggleBtn.addEventListener("keydown", function (e) {
				if (e.key === "Enter" || e.key === " ") {
					e.preventDefault();
					toggleSidebar();
				}
			});

			function applyAutoCollapse(isInitialLoad) {
				var currentWidth = window.innerWidth || document.body.clientWidth;
				if (!isInitialLoad && currentWidth === lastWidth) return;
				lastWidth = currentWidth;
				if (currentWidth < 992) {
					if (!sidebar.classList.contains("wiki-sidebar--hidden")) {
						toggleSidebar(true, false);
					}
				} else {
					var savedState = getSidebarState();
					if (
						savedState !== "collapsed" &&
						sidebar.classList.contains("wiki-sidebar--hidden")
					) {
						toggleSidebar(false, false);
					}
				}
			}

			function scheduleAutoCollapse() {
				if (resizeTimer) clearTimeout(resizeTimer);
				resizeTimer = setTimeout(function () {
					applyAutoCollapse(false);
				}, 100);
			}

			applyAutoCollapse(true);
			window.addEventListener("resize", scheduleAutoCollapse);
		}

		mw.loader.using(["mediawiki.api", "mediawiki.util"]).then(function () {
			var cachedContent = null;

			try {
				cachedContent = window.localStorage.getItem(CACHE_KEY);
			} catch (e) {}

			// 步骤1：如果有缓存，瞬间渲染
			if (cachedContent) {
				renderSidebar(cachedContent);
				console.log(
					"%c Gadget-Sidebar %c Loaded from Local Cache (SWR Mode)",
					"color: #334155; padding: 5px 0; background: rgba(248, 249, 250, 0.9);",
					"padding: 5px 5px 5px 0; background: #fff;"
				);
			}

			// 步骤2：后台静默获取最新数据，进行指纹比对
			var api = new mw.Api();
			api
				.get({
					action: "query",
					prop: "revisions",
					titles: "MediaWiki:Sidebar",
					rvprop: "content",
					rvslots: "main",
					formatversion: 2,
				})
				.done(function (data) {
					var pages =
						data && data.query && data.query.pages ? data.query.pages : null;
					var page = pages
						? Array.isArray(pages)
							? pages[0]
							: Object.values(pages)[0]
						: null;
					if (!page || !page.revisions) return;

					var freshContent = page.revisions[0].slots.main.content || "";

					// 步骤3：指纹比对。如果不一致，更新本地存储。
					if (freshContent !== cachedContent) {
						try {
							window.localStorage.setItem(CACHE_KEY, freshContent);
						} catch (e) {}
						if (!cachedContent) {
							renderSidebar(freshContent);
							console.log(
								"%c Gadget-Sidebar %c Rendered from Fresh API",
								"color: #334155; padding: 5px 0; background: rgba(248, 249, 250, 0.9);",
								"padding: 5px 5px 5px 0; background: #fff;"
							);
						} else {
							console.log(
								"%c Gadget-Sidebar",
								"color: #334155; padding: 5px 0; background: rgba(248, 249, 250, 0.9);",
								"padding: 5px 5px 5px 0; background: #fff;"
							);
						}
					}
				})
				.fail(function (error) {
					console.error("侧边栏数据请求失败:", error);
				});
		});
	}

	if (document.readyState === "loading") {
		document.addEventListener("DOMContentLoaded", initWikiSidebar);
	} else {
		initWikiSidebar();
	}
});