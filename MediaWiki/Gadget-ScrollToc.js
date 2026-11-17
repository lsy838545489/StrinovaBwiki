"use strict";

(window.RLQ = window.RLQ || []).push(function () {
	// 全局命名空间
	var ScrollToc = (window.GadgetScrollToc = window.GadgetScrollToc || {});
	ScrollToc.state = ScrollToc.state || {
		initialized: false,
		mwHookBound: false,
		toc: null,
		activeIndex: -1,
		tocLinks: [],
		titles: [],
		titleTop: [],
		parserOutput: null,

		scrollHandler: null,
		resizeHandler: null,
		hashChangeHandler: null,
		tocClickHandler: null,
		tocTitleHandler: null,

		mutationObserver: null,
		resizeObserver: null,

		refreshTimer: null,
		graceTimer: null,

		lastHashScrolled: "",
		isThrottled: false,
		scrollAnimationId: null,
		isAutoScrolling: false,
		userHasScrolled: false,
		initialGracePeriod: false,
	};

	ScrollToc.cleanup = function () {
		var s = this.state;

		if (s.scrollHandler) {
			document.removeEventListener("scroll", s.scrollHandler);
			s.scrollHandler = null;
		}

		if (s.resizeHandler) {
			window.removeEventListener("resize", s.resizeHandler);
			s.resizeHandler = null;
		}

		if (s.hashChangeHandler) {
			window.removeEventListener("hashchange", s.hashChangeHandler);
			s.hashChangeHandler = null;
		}

		if (s.toc && s.tocClickHandler) {
			s.toc.removeEventListener("click", s.tocClickHandler);
			s.tocClickHandler = null;
		}

		if (s.toc && s.tocTitleHandler) {
			s.toc.removeEventListener("click", s.tocTitleHandler);
			s.tocTitleHandler = null;
		}

		if (s.mutationObserver) {
			s.mutationObserver.disconnect();
			s.mutationObserver = null;
		}

		if (s.resizeObserver) {
			s.resizeObserver.disconnect();
			s.resizeObserver = null;
		}

		if (s.refreshTimer) {
			clearTimeout(s.refreshTimer);
			s.refreshTimer = null;
		}

		if (s.graceTimer) {
			clearTimeout(s.graceTimer);
			s.graceTimer = null;
		}

		if (s.scrollAnimationId) {
			window.cancelAnimationFrame(s.scrollAnimationId);
			s.scrollAnimationId = null;
		}

		s.isThrottled = false;
		s.isAutoScrolling = false;
		s.userHasScrolled = false;
		s.initialGracePeriod = false;
		s.activeIndex = -1;
	};

	ScrollToc.refreshData = function () {
		var s = this.state;
		var toc = s.toc;
		var parserOutput = s.parserOutput;

		s.tocLinks = [];
		s.titles = [];
		s.titleTop = [];

		if (!toc || !parserOutput) {
			return;
		}

		var headingMap = {};
		var headings = parserOutput.querySelectorAll("h1, h2, h3, h4, h5, h6");

		for (var i = 0; i < headings.length; i++) {
			var heading = headings[i];
			if (heading.id && heading.id !== "mw-toc-heading") {
				headingMap[heading.id] = heading;
			}
		}

		var links = toc.querySelectorAll("a");
		for (var j = 0; j < links.length; j++) {
			var link = links[j];
			var href = link.getAttribute("href") || "";
			if (href.charAt(0) !== "#") {
				continue;
			}

			var id = decodeURIComponent(href.slice(1));
			var target = headingMap[id] || document.getElementById(id) || null;

			s.tocLinks.push(link);
			s.titles.push(target);
			s.titleTop.push(null);
		}
	};

	ScrollToc.getOffsetTop = function (element) {
		var rect = element.getBoundingClientRect();
		var scrollTop = window.scrollY || document.documentElement.scrollTop || 0;
		return rect.top + scrollTop;
	};

	ScrollToc.calculateTitleOffsets = function (index) {
		var s = this.state;

		if (index !== undefined && index !== null) {
			if (s.titles[index]) {
				s.titleTop[index] = this.getOffsetTop(s.titles[index]);
			}
			return;
		}

		for (var i = 0; i < s.titles.length; i++) {
			if (s.titles[i]) {
				s.titleTop[i] = this.getOffsetTop(s.titles[i]);
			} else {
				s.titleTop[i] = null;
			}
		}
	};

	ScrollToc.findLinkIndexById = function (id) {
		var s = this.state;
		for (var i = 0; i < s.tocLinks.length; i++) {
			var href = s.tocLinks[i].getAttribute("href") || "";
			if (href.charAt(0) === "#" && decodeURIComponent(href.slice(1)) === id) {
				return i;
			}
		}
		return -1;
	};

	ScrollToc.setActive = function (index) {
		var s = this.state;
		var toc = s.toc;

		if (!toc || !s.tocLinks.length) {
			return;
		}

		if (s.activeIndex === index) {
			return;
		}

		s.activeIndex = index;

		for (var i = 0; i < s.tocLinks.length; i++) {
			s.tocLinks[i].classList.remove("titleActive");
		}

		if (s.tocLinks[index]) {
			s.tocLinks[index].classList.add("titleActive");
		}

		var tocUl = toc.querySelector("ul");
		if (tocUl && s.tocLinks[index]) {
			var targetScroll = s.tocLinks[index].offsetTop - tocUl.clientHeight / 4;
			tocUl.scrollTop = targetScroll;
		}
	};

	ScrollToc.syncActiveState = function () {
		if (this.state.tocLinks.length > 0) {
			this.setActive(0);
		}
	};

	ScrollToc.updateActiveByScroll = function () {
		var s = this.state;
		if (!s.tocLinks.length) {
			return;
		}

		var currentScrollY = window.scrollY || document.documentElement.scrollTop || 0;
		var index = 0;

		for (var i = 0; i < s.titleTop.length; i++) {
			if (s.titleTop[i] === null || s.titleTop[i] === undefined) {
				continue;
			}

			if (currentScrollY >= s.titleTop[i] - window.innerHeight / 3 - 30) {
				index = i;
			} else {
				break;
			}
		}

		this.setActive(index);
	};

	ScrollToc.scrollToSmooth = function (targetY, duration) {
		var s = this.state;
		var startY = window.scrollY || document.documentElement.scrollTop || 0;
		var startX = window.scrollX || document.documentElement.scrollLeft || 0;
		var difference = targetY - startY;
		var startTime = null;
		var self = this;

		if (s.scrollAnimationId) {
			window.cancelAnimationFrame(s.scrollAnimationId);
			s.scrollAnimationId = null;
		}

		s.isAutoScrolling = true;

		function step(currentTime) {
			if (!startTime) {
				startTime = currentTime;
			}

			var progress = currentTime - startTime;
			var percentage = Math.min(progress / duration, 1);
			var easing =
				percentage < 0.5
					? 2 * percentage * percentage
					: -1 + (4 - 2 * percentage) * percentage;

			window.scrollTo(startX, startY + difference * easing);

			if (progress < duration) {
				s.scrollAnimationId = window.requestAnimationFrame(step);
			} else {
				s.scrollAnimationId = null;
				s.isAutoScrolling = false;
				self.updateActiveByScroll();
			}
		}

		s.scrollAnimationId = window.requestAnimationFrame(step);
	};

	ScrollToc.scrollToTarget = function (index) {
		var s = this.state;
		if (s.titleTop[index] === null || s.titleTop[index] === undefined) {
			return;
		}
		this.scrollToSmooth(s.titleTop[index] - window.innerHeight / 3, 350);
	};

	ScrollToc.applyHashScroll = function () {
		var s = this.state;
		var currentHash = decodeURIComponent((location.hash || "").replace(/^#/, ""));
		if (!currentHash || currentHash === s.lastHashScrolled) {
			return;
		}

		var index = this.findLinkIndexById(currentHash);
		if (index === -1 || !s.titles[index]) {
			return;
		}

		s.lastHashScrolled = currentHash;
		var self = this;
		
		setTimeout(function () {
			if (s.titleTop[index] === null || s.titleTop[index] === undefined) {
				self.calculateTitleOffsets(index);
			}

			if (s.userHasScrolled) {
				return;
			}

			if (
				s.titleTop[index] !== null &&
				s.titleTop[index] !== undefined &&
				s.titleTop[index] > 0
			) {
				self.scrollToSmooth(s.titleTop[index] - window.innerHeight / 3, 350);
			}
		}, 200);
	};

	ScrollToc.checkRightSpace = function () {
		var s = this.state;
		var toc = s.toc;

		if (!toc) return;
		if (document.getElementById("nostickylefttoc")) return;

		var gameBg = document.querySelector(".game-bg");
		var gameBgWidth = gameBg ? gameBg.offsetWidth : 0;
		var bodyWidth = document.body.clientWidth;
		var rightBlankSpace =
			gameBgWidth > 0 ? (bodyWidth - gameBgWidth) / 2 : bodyWidth / 2;

		if (rightBlankSpace < 280 || bodyWidth < 900) {
			if (!toc.classList.contains("hidetoc")) {
				toc.classList.add("hidetoc");
			}
		} else {
			toc.classList.remove("hidetoc");
		}
	};

	ScrollToc.bindEvents = function () {
		var self = this;
		var s = this.state;
		var toc = s.toc;

		if (!toc) return;

		s.tocClickHandler = function (e) {
			var target = e.target;
			while (target && target !== toc && target.tagName !== "A") {
				target = target.parentNode;
			}

			if (!target || target.tagName !== "A") return;

			var href = target.getAttribute("href") || "";
			if (href.charAt(0) !== "#") return;

			e.preventDefault();
			e.stopImmediatePropagation();

			var id = decodeURIComponent(href.slice(1));
			var index = self.findLinkIndexById(id);
			if (index === -1 || !s.titles[index]) return;

			self.calculateTitleOffsets(index);
			self.scrollToTarget(index);

			if (window.history && history.pushState) {
				history.pushState(null, "", href);
			}
		};
		toc.addEventListener("click", s.tocClickHandler, false);

		s.tocTitleHandler = function (e) {
			var node = e.target;
			while (node && node !== toc) {
				if (node.tagName === "A") return;
				node = node.parentNode;
			}
			toc.classList.toggle("hidetoc");
		};
		toc.addEventListener("click", s.tocTitleHandler, false);

		s.scrollHandler = function () {
			if (s.isAutoScrolling) return;
			if (!s.initialGracePeriod) s.userHasScrolled = true;
			
			if (!s.isThrottled) {
				window.requestAnimationFrame(function () {
					self.updateActiveByScroll();
					s.isThrottled = false;
				});
				s.isThrottled = true;
			}
		};
		document.addEventListener("scroll", s.scrollHandler, { passive: true });

		s.resizeHandler = function () {
			self.checkRightSpace();
			self.calculateTitleOffsets();
			self.updateActiveByScroll();
		};
		window.addEventListener("resize", s.resizeHandler, false);

		s.hashChangeHandler = function () {
			self.applyHashScroll();
		};
		window.addEventListener("hashchange", s.hashChangeHandler, false);
	};

	ScrollToc.bindObservers = function () {
		var self = this;
		var s = this.state;
		var contentElement = document.querySelector("#mw-content-text");

		if (!contentElement) return;

		if (window.ResizeObserver) {
			s.resizeObserver = new ResizeObserver(function () {
				self.scheduleRefresh();
			});
			s.resizeObserver.observe(contentElement);
		}

		if (window.MutationObserver) {
			s.mutationObserver = new MutationObserver(function () {
				self.scheduleRefresh();
			});
			s.mutationObserver.observe(contentElement, {
				childList: true,
				subtree: true,
			});
		}
	};

	ScrollToc.bindMediaWikiHooks = function () {
		var self = this;
		var s = this.state;
		
		if (s.mwHookBound) return;
		
		if (window.mw && mw.hook) {
			mw.hook('wikipage.content').add(function ($content) {
				if (s.initialized) {
					self.scheduleRefresh(true);
				}
			});
			s.mwHookBound = true;
		}
	};

	ScrollToc.scheduleRefresh = function (force) {
		var self = this;
		var s = this.state;

		if (s.refreshTimer) {
			clearTimeout(s.refreshTimer);
		}

		s.refreshTimer = setTimeout(function () {
			s.refreshTimer = null;

			if (force) {
				self.init();
			} else {
				self.refreshData();
				self.calculateTitleOffsets();
				self.updateActiveByScroll();
				self.checkRightSpace();
			}
		}, 150);
	};

	ScrollToc.init = function () {
		this.cleanup();

		if (window.innerWidth < 768) {
			return;
		}

		if (document.getElementById("noscrolltoc")) {
			return;
		}

		var toc = document.getElementById("toc");
		var parserOutput = document.querySelector(".mw-parser-output");

		if (!toc || !parserOutput) {
			return;
		}

		this.state.toc = toc;
		this.state.parserOutput = parserOutput;
		this.state.lastHashScrolled = "";
		this.state.userHasScrolled = false;
		this.state.isAutoScrolling = false;
		this.state.initialGracePeriod = true;

		var self = this;
		if (this.state.graceTimer) {
			clearTimeout(this.state.graceTimer);
		}
		this.state.graceTimer = setTimeout(function () {
			self.state.initialGracePeriod = false;
			self.state.graceTimer = null;
		}, 300);

		if (toc.parentNode !== document.body) {
			document.body.appendChild(toc);
		}

		toc.classList.add("scrolltoc");

		this.refreshData();
		this.bindEvents();
		this.calculateTitleOffsets();
		this.syncActiveState();
		this.checkRightSpace();

		this.bindObservers();
		this.bindMediaWikiHooks();

		console.log(
			"%c Gadget-ScrollToc",
			"color: #1e293b; padding: 5px 0; background: rgba(241, 245, 249, 0.9);",
			"padding: 5px 5px 5px 0; background: #fff;"
		);

		this.applyHashScroll();
		this.state.initialized = true;
	};

	function initScrollToc() {
		ScrollToc.init();
	}

	if (document.readyState === "loading") {
		document.addEventListener("DOMContentLoaded", initScrollToc);
	} else {
		initScrollToc();
	}
});