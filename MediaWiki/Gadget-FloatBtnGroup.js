"use strict";

(function () {
    function isNode(value) {
        return !!value && typeof value === "object" && typeof value.nodeType === "number";
    }

    function sanitizeSvgString(svgString) {
        if (typeof svgString !== "string") return null;

        var parser = new DOMParser();
        var doc = parser.parseFromString(svgString, "text/html");

        var root = doc.querySelector("svg");
        if (!root) return null;

        var dangerousTags = {
            script: true,
            iframe: true,
            object: true,
            embed: true,
            foreignobject: true,
            audio: true,
            video: true
        };

        var walker = document.createTreeWalker(root, NodeFilter.SHOW_ELEMENT, null, false);
        var nodes = [];
        while (walker.nextNode()) {
            nodes.push(walker.currentNode);
        }

        for (var i = 0; i < nodes.length; i++) {
            var el = nodes[i];
            var tagName = el.nodeName.toLowerCase();

            if (dangerousTags[tagName]) {
                if (el.parentNode) el.parentNode.removeChild(el);
                continue;
            }

            var attrs = el.attributes;
            for (var j = attrs.length - 1; j >= 0; j--) {
                var attr = attrs[j];
                var name = attr.name.toLowerCase();
                var value = attr.value;

                if (name.indexOf("on") === 0) {
                    el.removeAttribute(attr.name);
                    continue;
                }

                if ((name === "href" || name === "xlink:href") && /^(?:\s*javascript:|\s*data:text\/html)/i.test(value)) {
                    el.removeAttribute(attr.name);
                }
            }
        }

        return root;
    }

    function appendIcon(target, icon) {
        if (!icon) return;

        // 支持直接传入 DOM 节点
        if (isNode(icon)) {
            target.appendChild(icon.cloneNode(true));
            return;
        }

        // 支持传入 SVG 字符串，但会做基础清理
        if (typeof icon === "string") {
            var svgEl = sanitizeSvgString(icon);
            if (svgEl) {
                target.appendChild(svgEl);
            } else {
                // 解析失败时，退化为纯文本，避免直接注入 HTML
                target.textContent = icon;
            }
        }
    }

    function createToggleIcon() {
        var svgNS = "http://www.w3.org/2000/svg";
        var svg = document.createElementNS(svgNS, "svg");
        svg.setAttribute("viewBox", "0 0 24 24");
        svg.setAttribute("width", "22");
        svg.setAttribute("height", "22");
        svg.setAttribute("stroke", "currentColor");
        svg.setAttribute("stroke-width", "2.5");
        svg.setAttribute("fill", "none");
        svg.setAttribute("stroke-linecap", "round");
        svg.setAttribute("stroke-linejoin", "round");

        var polyline = document.createElementNS(svgNS, "polyline");
        polyline.setAttribute("points", "15 18 9 12 15 6");
        svg.appendChild(polyline);

        return svg;
    }

    function initFloatBtnGroup() {
        var body = document.body || document.documentElement;
        if (!body) return;

        // 1. 获取或创建最外层包裹容器
        var group = document.getElementById("float-btn-group");
        if (!group) {
            group = document.createElement("div");
            group.id = "float-btn-group";
            group.className = "float-btn-group";
            body.appendChild(group);
        }

        // 2. 确保 __top 区域存在（给别的模块站位）
        var topZone = group.querySelector(".float-btn-group__top");
        if (!topZone) {
            topZone = document.createElement("div");
            topZone.className = "float-btn-group__top";
            group.insertBefore(topZone, group.firstChild);
        }

        // 3. 确保主控区 __main 存在
        var mainZone = group.querySelector(".float-btn-group__main");
        if (!mainZone) {
            mainZone = document.createElement("div");
            mainZone.className = "float-btn-group__main";
            group.appendChild(mainZone);
        }

        // 4. 确保向左扩展区 __left 存在
        var leftZone = mainZone.querySelector(".float-btn-group__left");
        if (!leftZone) {
            leftZone = document.createElement("div");
            leftZone.className = "float-btn-group__left";
            mainZone.appendChild(leftZone);
        }

        // 5. 确保主开关 __toggle 存在
        var toggleBtn = mainZone.querySelector(".float-btn-group__toggle");
        if (!toggleBtn) {
            toggleBtn = document.createElement("button");
            toggleBtn.className = "float-btn-group__toggle";
            toggleBtn.title = "展开/收起";
            toggleBtn.appendChild(createToggleIcon());

            toggleBtn.addEventListener("click", function () {
                group.classList.toggle("float-btn-group--active");
            });

            mainZone.appendChild(toggleBtn);
        }

        // 6. 注册 API
        var WidgetAPI = {
            register: function (config) {
                if (!config || !config.id) return;
                if (document.getElementById(config.id)) return;

                var btn = document.createElement("button");
                btn.id = config.id;
                btn.className = "float-btn-group__item" + (config.className ? " " + config.className : "");
                btn.title = config.tooltip || "";

                // 这里不直接 innerHTML，改为安全插入
                appendIcon(btn, config.icon);

                if (typeof config.onClick === "function") {
                    btn.addEventListener("click", config.onClick);
                }

                leftZone.appendChild(btn);
                return btn;
            },

            unregister: function (id) {
                if (!id) return;
                var el = document.getElementById(id);
                if (el && el.parentNode === leftZone) {
                    leftZone.removeChild(el);
                }
            }
        };

        // 同时挂全局，避免 hook 先 fire 后监听收不到
        window.FloatBtnGroupAPI = WidgetAPI;

        if (window.mw && mw.hook) {
            mw.hook("FloatBtnGroup.ready").fire(WidgetAPI);
        }

        console.log(
            "%c Gadget-FloatBtnGroup %c Initialized",
            "color: #334155; padding: 5px 0; background: rgba(248, 249, 250, 0.9);",
            "padding: 5px 5px 5px 0; background: #fff;"
        );
    }

    // DOM 就绪后初始化
    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", initFloatBtnGroup);
    } else {
        initFloatBtnGroup();
    }
})();