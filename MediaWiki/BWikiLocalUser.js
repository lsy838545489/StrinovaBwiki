/*
* BWikiUser V0.3
* Author: Lu
* AI Refactor: ChatGPT + DeepSeek
* License: CC BY-SA
*
* 目标：单文件、零依赖、ES2021+，清晰的数据管线，最少工程化负担。
* 管线：
*   1) 收集 UID、注入空HTML占位
*   2) 批量取 Wiki 信息（组/编辑数/注册 1小时缓存 缓存到浏览器IndexedDB）
*   3) 按 UID 取头像信息（IndexedDB 7天缓存）
*   4) 渲染数据
*
* 参考项目，感谢：
* - 魔改于之前写的 wukong.wiki/MediaWiki:BWikiLocalUser.js
* - BWIKI用户标签扩展工具 马小萌  bid 123855714    wiki.biligame.com/wiki/用户:123855714/BilibiliUser
* - MediaWiki API Demos https://github.com/wikimedia/mediawiki-api-demos
**/

(() => {
  'use strict';

  // ---------- Util ----------
  const WIKI_NAME = (location.pathname.split('/')[1] || '').trim();
  const WIKI_URL = `https://wiki.biligame.com/${WIKI_NAME}`;
  const MW_API = `${WIKI_URL}/api.php`;

  const log = (...a) => console.debug('[BWikiUser]', ...a);
  const warn = (...a) => console.warn('[BWikiUser]', ...a);

  const qs = (sel, root) => (root || document).querySelector(sel);
  const qsa = (sel, root) => Array.from((root || document).querySelectorAll(sel));
  const uniqNums = arr => [...new Set(arr)].filter(s => /^\d+$/.test(s));
  const once = (fn) => { let ran = false; return (...a) => { if (!ran) { ran = true; return fn(...a); } }; };
  const waitForElm = (sel) => new Promise(res => { //  Wait for element
    if (qs(sel)) return res(qs(sel));
    const ob = new MutationObserver(() => { const el = qs(sel); if (el) { ob.disconnect(); res(el); } });
    ob.observe(document.body, { childList: true, subtree: true });
  });

  // ---------- CSS（尽量少且聚合） ----------
  const injectStyle = once(() => {
    const css = `
      .user_func_link a{display:none}
      .comment-post:hover .user_func_link a{display:inline}
      .user_func_link a{color:rgba(0,0,0,.35)}
      .mediawiki .wiki-componment-rank .rank-top3 .rank-item-wrap .rank-item .rank-item-detail-wrap{margin-top:0}
      .mediawiki.mw-special-Recentchanges table span.changedby{display:inline}
      .buser_avatar img{height:24px;width:auto;margin:2px;border-radius:15px;border:1px solid #daa52040;image-rendering:auto}
    `;
    const s = document.createElement('style');
    s.textContent = css;
    document.head.appendChild(s);
  });


  // ---------- Groups → short labels ----------
  function group2text(groups) {
    if (!groups) return [];
    const g2text = {
      'bureaucrat': (WIKI_NAME === 'klbq' ? '猫娘站长喵' : '猫娘站长喵'),
      'sysop': '管理员喵', 
      'moderator': '版主喵', 
      'suppress': '监督员喵',
      'interface-admin': '界面管理员喵', 
      'widgeteditor': '小部件编辑喵', 
      'automoderated': '量产型猫娘喵'
    };
    const out = [];
    for (const k of Object.keys(g2text)) {
      if (groups.includes(k)) {
        out.push(g2text[k]);
        if (k === 'bureaucrat' || k === 'sysop') break;
      }
    }
    return out;
  }

  // =====================================================
  // Inject（只负责“找DOM + 插入占位 + 收集UID”）
  // =====================================================
  const Inject = {
    // 最近更改/历史等：.mw-userlink（父元素首位插入头像占位 + group 占位）
    fromUserLinks() {
      const ids = [];
      qsa('.mw-userlink').forEach(link => {
        const uid = (link.textContent || '').replace(/[()]/g, '').trim();
        if (!uid) return;
        ids.push(uid);

        const parent = link.parentElement;
        if (!parent.querySelector(`.buser_${uid}_group`)) {
          parent.insertAdjacentHTML('afterbegin', `<span class="buser_avatar buser_${uid}_avatar" data-uid="${uid}"></span>`);
          link.insertAdjacentHTML('beforebegin', ` <span class="buser_${uid}_group"></span> `);
        }
      });
      return uniqNums(ids);
    },

    // 页面贡献者列表（页面已有悬浮卡片，直接在卡片内追加占位）
    fromEditRank() {
      const ids = [];
      qsa('.rank-item-wrap').forEach(wrap => {
        const a = wrap.querySelector('a');
        const uid = a ? (a.href.split('/')[3] || '').trim() : '';
        if (!uid) return;
        ids.push(uid);

        const box = wrap.querySelector('.rank-item-detail-wrap');
        if (!box || box.querySelector(`.buser_${uid}`)) return;
        box.insertAdjacentHTML('beforeend', `
          <div class="buser_${uid}" data-uid="${uid}" style="padding:5px 16px;background:#fff;">
            <span class="buser_${uid}_group"></span><span class="buser_${uid}_editcount"></span><br>
            <span>
                <a href="${WIKI_URL}/用户:${uid}">用户页</a> •
                <a href="${WIKI_URL}/特殊:用户贡献/${uid}">贡献</a> •
                <a href="${WIKI_URL}/特殊:文件列表/${uid}">文件</a> •
                <a href="${WIKI_URL}/特殊:日志/${uid}">日志</a> • 
                <a href="${WIKI_URL}/特殊:用户权限/${uid}">权限</a>
            </span><br>
            <span class="buser_${uid}_label"></span><span class="buser_${uid}_registration"></span>
          </div>
        `);
      });
      return uniqNums(ids);
    },

    // 评论区
    fromComments() {
      const ids = [];
      qsa('.comment-body').forEach(node => {
        const a = qs('.comment-user a', node);
        const uid = a ? (a.getAttribute('href') || '').split('/')[3] : '';
        if (!uid) return;
        ids.push(uid);

        const nameEl = qs('.comment-user-name', node);
        if (nameEl && !qs(`.buser_${uid}_group`, nameEl)) {
          nameEl.insertAdjacentHTML('beforeend', ` <span class="buser_${uid}_group" data-uid="${uid}"></span> `);
        }
        const footer = qs('.comment-footer', node);
        if (footer && !qs('.user_func_link', footer)) {
          footer.insertAdjacentHTML('beforeend',`<span class="user_func_link"><a href="${WIKI_URL}/用户:${uid}">用户页</a>&nbsp;&nbsp;<a href="${WIKI_URL}/特殊:用户贡献/${uid}">贡献</a>&nbsp;&nbsp;<a href="${WIKI_URL}/特殊:文件列表/${uid}">文件</a>&nbsp;&nbsp;<a href="${WIKI_URL}/特殊:日志/${uid}">日志</a>&nbsp;&nbsp;<a href="${WIKI_URL}/特殊:用户权限/${uid}">权限</a></span>`);
        }
      });
      return uniqNums(ids);
    }
  };

  // =====================================================
  // Render（只负责把数据写进占位）
  // =====================================================
  const Render = {
    avatar(uid, detail) {
      if (!uid || !detail) return;
      let src = detail.face || '';
      const html = src ? `<img src="${src}" decoding="async">` : '';
      qsa(`.buser_${uid}_avatar`).forEach(el => { el.innerHTML = html; });
    },
    wikiInfo(list /* [[uid, info], ...] */) {
      if (!list || !list.length) return;
      for (const [uid, info] of list) {
        const groups = info.groups || [];
        const editcount = info.editcount || 0;
        const reg = info.registration ? new Date(info.registration) : null;

        if (groups.length) {
          const txt = group2text(groups).join(' ');
          qsa(`.buser_${uid}_group`).forEach(n => n.textContent = txt);
        }
        if (editcount > 0) {
          const t = `贡献${editcount}次`;
          qsa(`.buser_${uid}_editcount`).forEach(n => n.textContent = t);
        }
        if ('sign' in info && info.sign) {
          const t = `签名：${info.sign}`;
          qsa(`.buser_${uid}_label`).forEach(n => n.textContent = t);
        }
        if (reg) {
          const d = reg.toISOString().split('T')[0];
          const t = `首次访问：${d}`;
          qsa(`.buser_${uid}_registration`).forEach(n => n.textContent = t);
        }
      }
    }
  };


  // =====================================================
  // Data（只负责拿数据 / 缓存）
  // =====================================================
  const Data = {
    // ---- 小工具：KV 型 IndexedDB ----
    async openKV(dbName) {
      return new Promise((resolve, reject) => {
        const req = indexedDB.open(dbName, 1);
        req.onupgradeneeded = e => e.target.result.createObjectStore('u', { keyPath: 'uid' });
        req.onsuccess = e => resolve({
          db: e.target.result,
          store: mode => e.target.result.transaction('u', mode).objectStore('u')
        });
        req.onerror = () => reject(req.error);
      });
    },
    kvGet(store, uid) {
      return new Promise((resolve) => {
        const req = store('readonly').get(uid); 
        req.onsuccess = () => resolve(req.result || null); 
        req.onerror = () => resolve(null);
      });
    },
    kvPut(store, uid, data, ts) {
      return new Promise((resolve) => {
        const req = store('readwrite').put({ uid, ts, data });
        req.onsuccess = req.onerror = () => resolve();
      });
    },

    // MW：批量查用户（<=50）+ IndexedDB 1小时缓存
    async mwUsersBatch(uids) {
      const TTL_1H = 60 * 60 * 1000;
      const nowMs = Date.now();

      const { store } = await Data.openKV('BUserGroups_' + WIKI_NAME); // wiki单独库
      const fresh = [], need = [], staleMap = new Map();

      // 读缓存与 TTL 判断
      await Promise.all(uids.map(async (uid) => {
        const rec = await Data.kvGet(store, uid);
        if (rec && (nowMs - rec.ts) < TTL_1H) fresh.push([uid, rec.data]);
        else {
          if (rec) staleMap.set(uid, rec.data);
          need.push(uid);
        }
      }));

      if (!need.length) return fresh;

      try {
        const url = `${MW_API}?` + new URLSearchParams({
          action: 'query', list: 'users', format: 'json',
          ususers: need.join('|'), usprop: 'groups|editcount|registration|blockinfo'
        });
        const json = await (await fetch(url)).json();
        const usersArr = json?.query?.users || [];
        const result = [...fresh];

        await Promise.all(usersArr.map(async (user) => {
          if (!('missing' in user)) {
            result.push([user.name, user]); // 这里“name”即数字 bid
            await Data.kvPut(store, user.name, user, nowMs);
          }
        }));

        return result;
      } catch (err) {
        log('mwUsersBatch fetch failed, fallback once to stale', err);
        const result = [...fresh];
        need.forEach((uid) => { if (staleMap.has(uid)) result.push([uid, staleMap.get(uid)]); });
        return result;
      }
    },

    async mwUsersAll(uids) {
      for (let i = 0; i < uids.length; i += 50) {
        try {
          Render.wikiInfo(await Data.mwUsersBatch(uids.slice(i, i + 50)));
        } catch (e) { warn('mwUsersAll batch failed', e); }
      }
    },

    // 头像：IndexedDB 7天缓存
    async getAvatar(uid) {
      const TTL_7D = 7 * 24 * 60 * 60 * 1000, nowMs = Date.now();
      const { store } = await Data.openKV('BUserAvatar'); // 共用数据库
      const cached = await Data.kvGet(store, uid);
      if (cached && (nowMs - cached.ts) < TTL_7D) return cached.data;

      try {
        const json = await (await fetch(`https://line1-h5-pc-api.biligame.com/game/user/space/user_detail?uid=${uid}`)).json();
        const data = json?.data;
        await Data.kvPut(store, uid, data, nowMs);
        return data;
      } catch (_) { /* 静默失败，走兜底 */ }

      return cached ? cached.data : null;
    },

    async avatarsAll(uids) {
      for (const uid of uids) {
        try {
          const d = await Data.getAvatar(uid);
          if (d) Render.avatar(uid, d);
        } catch (e) { warn('avatar failed', uid, e); }
      }
    }
  };

  // =====================================================
  // Main（流程与时序）
  // =====================================================
  const Main = {
    run() {
      if (window._BWikiUser_is_load) { log('BWikiUser already loaded'); return; }
      window._BWikiUser_is_load = true;

      injectStyle();

      // 1) 主文档可见的用户：立即注入与收集
      let uids = [
        ...Inject.fromUserLinks(),
        ...Inject.fromEditRank()
      ];
      uids = uniqNums(uids);

      if (uids.length) {
        // 并发分支，互不阻塞
        queueMicrotask(() => Data.mwUsersAll(uids));
        queueMicrotask(() => Data.avatarsAll(uids));
      }

      // 2) 评论区：独立等待，不影响主流程
      waitForElm('.comment-post').then(() => {
        try {
          const cuids = Inject.fromComments();
          if (cuids.length) queueMicrotask(() => Data.mwUsersAll(cuids));
        } catch (e) { warn('comments inject failed', e); }
      }).catch(() => { /* ignore */ });

      // 3) 最近更改：动态刷新时重扫并更新
      if (document.body.classList.contains('mw-special-Recentchanges')) {
        const triggerRCRefresh = (() => {
          let t;
          return () => {
            // 简易去抖：合并短时间内的多次变更
            clearTimeout(t);
            t = setTimeout(() => {
              const u = uniqNums(Inject.fromUserLinks());
              if (u.length) {
                try {
                  queueMicrotask(() => Data.mwUsersAll(u));
                  queueMicrotask(() => Data.avatarsAll(u));
                } catch (e) { warn && warn('RC refresh failed', e); }
              }
            }, 60);
          };
        })();

        // 监听最近更改页面的内容变化
        const installRCHook = () => {
          try {
            // MediaWiki 在 AJAX 注入新内容后会触发该 hook
            mw.hook('wikipage.content').add(($content) => {
              const root = $content && $content[0];
              if (!root) return;
              // 仅在本页且变更涉及 .mw-changeslist 时触发
              if ((root.closest && root.closest('.mw-changeslist')) ||
                  (root.querySelector && root.querySelector('.mw-changeslist'))) {
                triggerRCRefresh();
              }
            });
          } catch (e) { warn('installRCHook failed', e); }
        };

        if (window.mw && mw.hook) {
          installRCHook();
        } else {  // 等待 mw.hook 加载，但似乎没有对应的组件，因此等待'jquery'
          (window.RLQ = window.RLQ || []).push([['jquery'], installRCHook]);
        }
      }
    }
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => Main.run(), { once: true });
  } else {
    Main.run();
  }
})();