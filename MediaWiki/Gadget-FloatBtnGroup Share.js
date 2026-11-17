"use strict";

(function () {
    function showToast(msg) {
        var toast = document.createElement('div');
        toast.className = 'float-btn-group__toast';
        toast.textContent = msg;

        document.body.appendChild(toast);

        setTimeout(function () {
            toast.className = 'float-btn-group__toast float-btn-group__toast--show';
        }, 10);

        setTimeout(function () {
            toast.className = 'float-btn-group__toast';
            setTimeout(function () {
                if (toast.parentNode) {
                    toast.parentNode.removeChild(toast);
                }
            }, 300);
        }, 2000);
    }

    function copyText(text) {
        if (navigator.clipboard && typeof navigator.clipboard.writeText === 'function') {
            return navigator.clipboard.writeText(text);
        }

        return new Promise(function (resolve, reject) {
            var tempInput = document.createElement('input');
            tempInput.value = text;
            tempInput.setAttribute('readonly', 'readonly');
            tempInput.style.position = 'fixed';
            tempInput.style.left = '-9999px';
            tempInput.style.top = '-9999px';

            document.body.appendChild(tempInput);
            tempInput.select();
            tempInput.setSelectionRange(0, tempInput.value.length);

            try {
                var success = document.execCommand('copy');
                document.body.removeChild(tempInput);
                if (success) {
                    resolve();
                } else {
                    reject(new Error('copy failed'));
                }
            } catch (err) {
                document.body.removeChild(tempInput);
                reject(err);
            }
        });
    }

    function register(WidgetAPI) {
        if (!WidgetAPI || typeof WidgetAPI.register !== 'function') return;

        var linkIcon = '<svg viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2.5" fill="none" stroke-linecap="round" stroke-linejoin="round"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"></path><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"></path></svg>';

        WidgetAPI.register({
            id: 'float-btn-group-share-link',
            icon: linkIcon,
            tooltip: '复制本页短链接',
            onClick: function () {
                var pageId = mw.config.get('wgArticleId');
                var shortUrl = '';
                if (pageId > 0) {
                    shortUrl = mw.config.get('wgServer') + mw.config.get('wgScript') + '?curid=' + pageId;
                } else {
                    shortUrl = window.location.href.split('#')[0];
                }

                copyText(shortUrl).then(function () {
                    showToast('短链接已复制喵！');
                }).catch(function () {
                    showToast('复制失败，请手动复制');
                });
            }
        });
    }

    if (window.FloatBtnGroupAPI) {
        register(window.FloatBtnGroupAPI);
        return;
    }

    mw.hook('FloatBtnGroup.ready').add(register);
})();