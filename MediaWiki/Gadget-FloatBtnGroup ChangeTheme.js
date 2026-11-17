"use strict";

(function instantDarkModeInit() {
    try {
        if (localStorage.getItem('wiki-ui-dark') === 'true') {
            document.documentElement.classList.add('wiki-dark-mode');
        }
    } catch (e) {
    }
})();

// =========================================================================
// 核心模块逻辑
// =========================================================================
(function () {
    var storageKey = 'wiki-ui-dark';
    var btnId = 'float-btn-group-theme-toggle';
    var styleId = 'float-btn-group-theme-style';

    var cachedMoon = null;
    var cachedSun = null;

    var iconMoon = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="22" height="22" fill="currentColor"><path d="M12 3c-4.97 0-9 4.03-9 9s4.03 9 9 9 9-4.03 9-9c0-.46-.04-.92-.1-1.36-.98 1.37-2.58 2.26-4.4 2.26-2.98 0-5.4-2.42-5.4-5.4 0-1.81.89-3.42 2.26-4.4-.44-.06-.9-.1-1.36-.1z"/></svg>';
    var iconSun = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="22" height="22" fill="currentColor"><path d="M12 7c-2.76 0-5 2.24-5 5s2.24 5 5 5 5-2.24 5-5-2.24-5-5-5zM2 13h2c.55 0 1-.45 1-1s-.45-1-1-1H2c-.55 0-1 .45-1 1s.45 1 1 1zm18 0h2c.55 0 1-.45 1-1s-.45-1-1-1h-2c-.55 0-1 .45-1 1s.45 1 1 1zM11 2v2c0 .55.45 1 1 1s1-.45 1-1V2c0-.55-.45-1-1-1s-1 .45-1 1zm0 18v2c0 .55.45 1 1 1s1-.45 1-1v-2c0-.55-.45-1-1-1s-1 .45-1 1zM5.99 4.58c-.39-.39-1.03-.39-1.41 0-.39.39-.39 1.03 0 1.41l1.06 1.06c.39.39 1.03.39 1.41 0 .39-.39.39-1.03 0-1.41L5.99 4.58zm12.37 12.37c-.39-.39-1.03-.39-1.41 0-.39.39-.39 1.03 0 1.41l1.06 1.06c.39.39 1.03.39 1.41 0 .39-.39.39-1.03 0-1.41l-1.06-1.06zm1.06-10.96c.39-.39.39-1.03 0-1.41-.39-.39-1.03-.39-1.41 0l-1.06 1.06c-.39.39-.39 1.03 0 1.41.39.39 1.03.39 1.41 0l1.06-1.06zM7.05 18.36c.39-.39.39-1.03 0-1.41-.39-.39-1.03-.39-1.41 0l-1.06 1.06c-.39.39-.39 1.03 0 1.41.39.39 1.03.39 1.41 0l1.06-1.06z"/></svg>';

    var memoryFallback = false;
    var hasRegistered = false;

    function safeGetDarkState() {
        try {
            var val = localStorage.getItem(storageKey);
            if (val !== null) return val === 'true';
            return memoryFallback;
        } catch (e) {
            return memoryFallback;
        }
    }

    function safeSetDarkState(isDark) {
        try {
            localStorage.setItem(storageKey, isDark ? 'true' : 'false');
            memoryFallback = isDark;
            return true;
        } catch (e) {
            memoryFallback = isDark;
            console.warn('FloatBtnGroup: 无法写入 localStorage，暗色模式状态仅在当前会话生效。');
            return false;
        }
    }

    function ensureTransitionStyle() {
        if (document.getElementById(styleId)) return;

        var transitionStyle = ''
            + '.game-bg, h1, h2, h3, h4, h5, h6, table.wikitable, table.wikitable > tr > th, '
            + 'table.wikitable > * > tr > th, table.wikitable > tr > td, table.wikitable > * > tr > td, '
            + '#toc, .toc, .thumbinner, .panel-heading, .decorative-sidebar, .wiki-panel-title, '
            + '.wiki-jump-btn a, .resp-tabs-list li .tab-panel { '
            + 'transition-property: background-color, color, border-color, box-shadow; '
            + 'transition-duration: 0.4s; '
            + 'transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1); '
            + '} '
            + '@media (prefers-reduced-motion: reduce) { '
            + '  .game-bg, h1, h2, h3, h4, h5, h6, table.wikitable, table.wikitable > tr > th, '
            + '  table.wikitable > * > tr > th, table.wikitable > tr > td, table.wikitable > * > tr > td, '
            + '  #toc, .toc, .thumbinner, .panel-heading, .decorative-sidebar, .wiki-panel-title, '
            + '  .wiki-jump-btn a, .resp-tabs-list li .tab-panel { '
            + '    transition: none !important; '
            + '  } '
            + '}';

        var styleEl = document.createElement('style');
        styleEl.id = styleId;
        styleEl.type = 'text/css';

        if (styleEl.styleSheet) {
            styleEl.styleSheet.cssText = transitionStyle;
        } else {
            styleEl.appendChild(document.createTextNode(transitionStyle));
        }

        document.head.appendChild(styleEl);
    }

    function parseSvg(svgString) {
        if (typeof svgString !== 'string') return null;
        var parser = new DOMParser();
        var doc = parser.parseFromString(svgString, 'text/html');
        var root = doc.querySelector('svg');
        if (!root) return null;
        return root;
    }

    function getCachedIcon(isDark) {
        if (isDark) {
            if (!cachedSun) cachedSun = parseSvg(iconSun);
            return cachedSun;
        } else {
            if (!cachedMoon) cachedMoon = parseSvg(iconMoon);
            return cachedMoon;
        }
    }

    function replaceButtonIcon(btnEl, isDark) {
        if (!btnEl) return false;
        var cached = getCachedIcon(isDark);
        if (!cached) return false;

        while (btnEl.firstChild) {
            btnEl.removeChild(btnEl.firstChild);
        }
        btnEl.appendChild(document.importNode(cached, true));
        return true;
    }

    function applyTheme(isDark) {
        var htmlEl = document.documentElement;
        var bodyEl = document.body;
        var btnEl = document.getElementById(btnId);

        if (isDark) {
            htmlEl.classList.add('wiki-dark-mode');
            if (bodyEl) bodyEl.classList.add('wiki-dark-mode');
        } else {
            htmlEl.classList.remove('wiki-dark-mode');
            if (bodyEl) bodyEl.classList.remove('wiki-dark-mode');
            
            // 【关键回调】：防重绘卡顿锁，修复暗切亮时文字颜色卡死的问题
            void document.body.offsetHeight; 
        }

        if (!replaceButtonIcon(btnEl, isDark)) {
            setTimeout(function () {
                var retryBtn = document.getElementById(btnId);
                if (retryBtn) replaceButtonIcon(retryBtn, isDark);
            }, 50);
        }
    }

    function syncThemeFromStorageEvent(e) {
        if (!e || e.key !== storageKey) return;
        var newState = (e.newValue === 'true');
        memoryFallback = newState;
        applyTheme(newState);
    }

    function registerThemeToggle(WidgetAPI) {
        if (hasRegistered) return;
        if (!WidgetAPI || typeof WidgetAPI.register !== 'function') return;

        var currentThemeIsDark = safeGetDarkState();

        WidgetAPI.register({
            id: btnId,
            tooltip: '切换亮/暗色模式',
            icon: currentThemeIsDark ? iconSun : iconMoon, // 初始使用字符串占位，挂载后立刻被 applyTheme 替换为原生 SVG 节点
            onClick: function () {
                var nextState = !safeGetDarkState();
                safeSetDarkState(nextState);
                applyTheme(nextState);
            }
        });

        applyTheme(currentThemeIsDark);
        hasRegistered = true;
    }

    function init() {
        // 由于已经在第一行进行了快速类名注入，这里仅负责补全动画和同步按钮状态
        ensureTransitionStyle();

        // 确保哪怕第一行被异常吃掉，这里也会进行二次兜底赋权
        var isDark = safeGetDarkState();
        if (isDark) {
            document.documentElement.classList.add('wiki-dark-mode');
            if (document.body) document.body.classList.add('wiki-dark-mode');
        }

        window.addEventListener('storage', syncThemeFromStorageEvent);

        if (window.FloatBtnGroupAPI) {
            registerThemeToggle(window.FloatBtnGroupAPI);
            return;
        }

        if (window.mw && mw.hook) {
            mw.hook('FloatBtnGroup.ready').add(function (api) {
                registerThemeToggle(api);
            });
        }

        // 终极延迟兜底挂载
        setTimeout(function () {
            if (hasRegistered) return;
            if (window.FloatBtnGroupAPI) {
                registerThemeToggle(window.FloatBtnGroupAPI);
            } else {
                console.warn('FloatBtnGroup: 主控模块未响应，暗色模式切换组件未能成功挂载。');
            }
        }, 2000);
    }

    // 监听 DOM 加载状态
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();