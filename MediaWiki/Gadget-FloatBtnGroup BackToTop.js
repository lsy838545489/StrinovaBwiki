"use strict";

(function () {

    function register(api) {
        var text = document.createElement('span');
        text.className = 'top-text';
        text.textContent = 'Top';

        api.register({
            id: 'float-btn-group-back-to-top',
            className: 'float-btn-group__item--text',
            icon: text,
            tooltip: '返回顶部',
            onClick: function () {
                window.scrollTo({
                    top: 0,
                    behavior: 'smooth'
                });
            }
        });
    }

    // 如果主模块已经加载完成
    if (window.FloatBtnGroupAPI) {
        register(window.FloatBtnGroupAPI);
        return;
    }

    // 等待主模块初始化
    mw.hook('FloatBtnGroup.ready').add(register);

})();