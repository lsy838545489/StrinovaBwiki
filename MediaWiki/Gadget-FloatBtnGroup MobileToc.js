(function (window, document) {
    "use strict";
    window.RLQ = window.RLQ || [];
    window.RLQ.push(function () {

        function domReady(callback) {
            if (document.readyState === "complete" || document.readyState === "interactive") {
                setTimeout(callback, 1);
            } else {
                document.addEventListener("DOMContentLoaded", callback, false);
            }
        }

        function hasClass(el, cls) {
            return !!el && (" " + el.className + " ").indexOf(" " + cls + " ") > -1;
        }

        function addClass(el, cls) {
            if (el && !hasClass(el, cls)) {
                el.className = (el.className ? el.className + " " : "") + cls;
            }
        }

        function removeClass(el, cls) {
            if (!el) return;
            var reg = new RegExp("(^|\\s)" + cls + "(?=\\s|$)", "g");
            el.className = el.className.replace(reg, " ").replace(/\s+/g, " ").replace(/^\s+|\s+$/g, "");
        }

        function closest(el, matcher) {
            while (el && el !== document) {
                if (matcher(el)) return el;
                el = el.parentNode;
            }
            return null;
        }

        var state = {
            initialized: false,
            opened: false,
            tocButton: null,
            toc: null,
            mask: null,
            group: null,
            handlers: {}
        };

        function cleanupOldDom() {
            var oldToc = document.getElementById("mw-toc");
            if (oldToc && oldToc.parentNode) oldToc.parentNode.removeChild(oldToc);

            var oldMask = document.querySelector(".mw-mask");
            if (oldMask && oldMask.parentNode) oldMask.parentNode.removeChild(oldMask);

            var oldBtn = document.getElementById("mobile-toc-btn");
            if (oldBtn && oldBtn.parentNode) oldBtn.parentNode.removeChild(oldBtn);
        }

        function destroy() {
            if (state.handlers.keydown) {
                document.removeEventListener("keydown", state.handlers.keydown, false);
            }
            if (state.toc && state.handlers.tocClick) {
                state.toc.removeEventListener("click", state.handlers.tocClick, false);
            }
            if (state.tocButton && state.handlers.buttonClick) {
                state.tocButton.removeEventListener("click", state.handlers.buttonClick, false);
                state.tocButton.removeEventListener("keydown", state.handlers.buttonKeydown, false);
            }
            if (state.mask && state.handlers.maskClick) {
                state.mask.removeEventListener("click", state.handlers.maskClick, false);
            }

            state.initialized = false;
            state.opened = false;
            state.tocButton = null;
            state.toc = null;
            state.mask = null;
            state.group = null;
            state.handlers = {};

            cleanupOldDom();
            removeClass(document.body, "overflowhidden");
        }

        function syncButtonState(isOpen) {
            if (!state.tocButton) return;
            state.tocButton.setAttribute("aria-label", isOpen ? "关闭目录" : "打开目录");
            state.tocButton.setAttribute("aria-expanded", String(!!isOpen));
        }

        function resetSubMenus() {
            if (!state.toc) return;

            var allIcons = state.toc.querySelectorAll("li > i");
            for (var i = 0; i < allIcons.length; i++) {
                allIcons[i].classList.remove("active");
                allIcons[i].setAttribute("aria-expanded", "false");
            }

            var allUls = state.toc.querySelectorAll("li > ul");
            for (var j = 0; j < allUls.length; j++) {
                var ul = allUls[j];
                ul.style.display = "none";
                ul.style.height = "";
                ul.style.overflow = "";
                ul.style.transition = "";
                ul.removeAttribute("data-animating");
            }
        }

        function slideToggle(element, duration) {
            if (!element) return;
            duration = typeof duration === "number" && duration >= 0 ? duration : 300;

            if (element.dataset.animating === "true") return;
            element.dataset.animating = "true";

            var style = window.getComputedStyle(element);
            var isHidden = style.display === "none";
            var finished = false;
            var timer = null;

            function finish(shouldHide) {
                if (finished) return;
                finished = true;

                if (timer) {
                    clearTimeout(timer);
                    timer = null;
                }

                element.style.height = "";
                element.style.overflow = "";
                element.style.transition = "";
                element.dataset.animating = "false";
                element.removeEventListener("transitionend", onTransitionEnd);

                if (shouldHide) {
                    element.style.display = "none";
                }
            }

            function onTransitionEnd(ev) {
                if (ev.target !== element || ev.propertyName !== "height") return;
                finish(!isHidden);
            }

            element.addEventListener("transitionend", onTransitionEnd);

            timer = setTimeout(function () {
                finish(!isHidden);
            }, duration + 120);

            if (isHidden) {
                element.style.display = "block";
                var height = element.scrollHeight;
                element.style.height = "0px";
                element.style.overflow = "hidden";
                element.style.transition = "height " + duration + "ms ease";
                element.offsetHeight;
                element.style.height = height + "px";
            } else {
                var currentHeight = element.scrollHeight;
                element.style.height = currentHeight + "px";
                element.style.overflow = "hidden";
                element.style.transition = "height " + duration + "ms ease";
                element.offsetHeight;
                element.style.height = "0px";
            }
        }

        function openToc() {
            if (!state.toc || state.opened) return;
            state.toc.classList.add("opentoc");
            if (state.mask) state.mask.style.display = "block";
            addClass(document.body, "overflowhidden");
            state.opened = true;
            syncButtonState(true);

            var closeBtn = state.toc.querySelector(".toc-close");
            if (closeBtn && closeBtn.focus) {
                setTimeout(function () {
                    closeBtn.focus();
                }, 0);
            }
        }

        function closeToc() {
            if (!state.toc || !state.opened) return;
            state.toc.classList.remove("opentoc");
            if (state.mask) state.mask.style.display = "none";
            removeClass(document.body, "overflowhidden");
            resetSubMenus();
            state.opened = false;
            syncButtonState(false);

            if (state.tocButton && state.tocButton.focus) {
                setTimeout(function () {
                    state.tocButton.focus();
                }, 0);
            }
        }

        function toggleToc() {
            if (state.opened) {
                closeToc();
            } else {
                openToc();
            }
        }

        function buildUI() {
            var tocSource = document.getElementById("toc");
            if (!tocSource) return false;

            var originalUl = document.querySelector("#toc > ul");
            if (!originalUl) return false;

            var clonedToc = originalUl.cloneNode(true);

            var icons = clonedToc.querySelectorAll("i");
            for (var i = 0; i < icons.length; i++) {
                if (icons[i].parentNode) {
                    icons[i].parentNode.removeChild(icons[i]);
                }
            }

            var lis = clonedToc.querySelectorAll("li");
            for (var j = 0; j < lis.length; j++) {
                var li = lis[j];
                var nestedUl = null;
                var children = li.children;

                for (var k = 0; k < children.length; k++) {
                    if (children[k].tagName === "UL") {
                        nestedUl = children[k];
                        break;
                    }
                }

                if (!nestedUl) continue;

                var toggleIcon = document.createElement("i");
                toggleIcon.className = "toc-subtoggle";
                toggleIcon.setAttribute("role", "button");
                toggleIcon.setAttribute("tabindex", "0");
                toggleIcon.setAttribute("aria-label", "展开或折叠子目录");
                toggleIcon.setAttribute("aria-expanded", "false");

                li.insertBefore(toggleIcon, nestedUl);
                nestedUl.style.display = "none";
            }

            var tocHtml = '<div id="mw-toc" class="mw-toc">' +
                '<div class="mw-toctitle" lang="zh-Hans-CN" dir="ltr">' +
                '<i class="toc-close" role="button" tabindex="0" aria-label="关闭目录"></i><h2 id="mw-toc-heading">目录</h2></div>' +
                clonedToc.outerHTML +
                '</div>';

            document.body.insertAdjacentHTML("beforeend", tocHtml);
            state.toc = document.getElementById("mw-toc");

            state.mask = document.querySelector(".mw-mask");
            if (!state.mask) {
                document.body.insertAdjacentHTML("beforeend", '<div class="mw-mask" style="display: none;"></div>');
                state.mask = document.querySelector(".mw-mask");
            }

            state.group = document.getElementById("float-btn-group");
            if (!state.group) {
                state.group = document.createElement("div");
                state.group.id = "float-btn-group";
                state.group.className = "float-btn-group";
                document.body.appendChild(state.group);
            }

            var topZone = state.group.querySelector(".float-btn-group__top");
            if (!topZone) {
                topZone = document.createElement("div");
                topZone.className = "float-btn-group__top";
                state.group.appendChild(topZone);
            }

            state.tocButton = document.createElement("div");
            state.tocButton.id = "mobile-toc-btn";
            state.tocButton.className = "mobile-toc";
            state.tocButton.setAttribute("role", "button");
            state.tocButton.setAttribute("tabindex", "0");
            state.tocButton.setAttribute("aria-label", "打开目录");
            state.tocButton.setAttribute("aria-expanded", "false");
            topZone.appendChild(state.tocButton);

            syncButtonState(false);

            state.handlers.tocClick = function (e) {
                var target = e.target;

                if (target && hasClass(target, "toc-close")) {
                    e.stopPropagation();
                    closeToc();
                    return;
                }

                var link = closest(target, function (node) {
                    return node && node.tagName === "A";
                });
                if (link && state.toc.contains(link)) {
                    var toggleIcon = link.parentNode ? link.parentNode.querySelector(":scope > .toc-subtoggle") : null;
                    if (toggleIcon) {
                        if (e.preventDefault) e.preventDefault();
                        e.stopPropagation();
                        
                        var ul = link.parentNode.querySelector(":scope > ul");
                        if (ul) {
                            toggleIcon.classList.toggle("active");
                            toggleIcon.setAttribute("aria-expanded", toggleIcon.classList.contains("active") ? "true" : "false");
                            slideToggle(ul, 300);
                        }
                        return; 
                    }
                    closeToc();
                    return;
                }
                
                var toggle = closest(target, function (node) {
                    return node && node.tagName === "I" && hasClass(node, "toc-subtoggle");
                });
                if (toggle && toggle.parentNode && toggle.parentNode.tagName === "LI") {
                    e.stopPropagation();
                    var ul = toggle.parentNode.querySelector("ul");
                    if (ul) {
                        toggle.classList.toggle("active");
                        toggle.setAttribute("aria-expanded", toggle.classList.contains("active") ? "true" : "false");
                        slideToggle(ul, 300);
                    }
                }
            };

            state.handlers.buttonClick = function (e) {
                e.stopPropagation();
                toggleToc();
            };

            state.handlers.buttonKeydown = function (e) {
                e = e || window.event;
                if (e.key === "Enter" || e.key === " " || e.key === "Spacebar") {
                    if (e.preventDefault) e.preventDefault();
                    toggleToc();
                }
            };

            state.handlers.maskClick = function () {
                closeToc();
            };

            state.handlers.keydown = function (e) {
                e = e || window.event;
                if (e.key === "Escape" || e.key === "Esc") {
                    closeToc();
                }
            };

            state.toc.addEventListener("click", state.handlers.tocClick, false);
            state.tocButton.addEventListener("click", state.handlers.buttonClick, false);
            state.tocButton.addEventListener("keydown", state.handlers.buttonKeydown, false);
            state.mask.addEventListener("click", state.handlers.maskClick, false);
            document.addEventListener("keydown", state.handlers.keydown, false);

            return true;
        }

        function init() {
            destroy();
            if (!buildUI()) return;
            state.initialized = true;
        }

        function refresh() {
            // 内容更新时直接重建，保证新 #toc 能被再次处理
            init();
        }

        domReady(init);

        if (window.mw && mw.hook && typeof mw.hook === "function") {
            mw.hook("wikipage.content").add(function () {
                refresh();
            });
        }

        console.log("%c Gadget-FloatBtnGroup_MobileToc %c Initialized", "color: #334155; padding: 5px 0; background: rgba(248, 249, 250, 0.9);", "padding: 5px 5px 5px 0; background: #fff;");
    });
}(window, document));