(function() {
    'use strict';
    
    var PREFIX_BASE = "000B";
    var HEX_LEN = 25;
    var FACTION_CODE = {
        "超弦体": "0002",
        "晶源体": "0003"
    };
    var cardDataCache = null;
    var cardIdToIndexMap = {};
    var indexToCardIdMap = {};
    
    function ensureMwApi(timeoutMs) {
        timeoutMs = typeof timeoutMs === "number" ? timeoutMs : 5000;
        return new Promise(function (resolve, reject) {
            try {
                mw.loader.load("mediawiki.api");
            } catch (e) {}
            var waited = 0,
                interval = 100;
            (function waitLoop() {
                if (window.mw && window.mw.Api) {
                    resolve();
                } else {
                    waited += interval;
                    if (waited >= timeoutMs) reject(new Error("mw.Api 加载超时"));
                    else setTimeout(waitLoop, interval);
                }
            })();
        });
    }
    
    function loadCardData() {
        return new Promise(function(resolve, reject) {
            if (cardDataCache) {
                resolve(cardDataCache);
                return;
            }
            
            ensureMwApi(5000).then(function() {
                var api = new mw.Api();
                api.get({
                    action: 'query',
                    prop: 'revisions',
                    titles: 'MediaWiki:ZombieCardList.json',
                    rvprop: 'content',
                    rvslots: 'main',
                    format: 'json'
                }).done(function(data) {
                    try {
                        var pages = data.query && data.query.pages;
                        var pageId = Object.keys(pages)[0];
                        var page = pages[pageId];
                        
                        if (page && page.missing) {
                            reject(new Error('数据源页面不存在'));
                            return;
                        }
                        
                        var content = (page && page.revisions && page.revisions[0].slots.main['*']) || '';
                        var jsonText = content.trim()
                            .replace(/^<pre[^>]*>/i, '')
                            .replace(/<\/pre>$/i, '')
                            .trim();
                        
                        cardDataCache = JSON.parse(jsonText);
                        
                        // 构建映射表
                        cardIdToIndexMap = {};
                        indexToCardIdMap = {};
                        
                        Object.keys(cardDataCache).forEach(function(faction) {
                            var cards = cardDataCache[faction];
                            if (Array.isArray(cards)) {
                                cards.forEach(function(card) {
                                    if (card && typeof card === 'object' && card.cardid && typeof card.index === 'number') {
                                        var cardId = String(card.cardid).trim();
                                        var index = card.index;
                                        cardIdToIndexMap[cardId] = index;
                                        indexToCardIdMap[index] = cardId;
                                    }
                                });
                            }
                        });
                        
                        resolve(cardDataCache);
                    } catch (e) {
                        reject(new Error('JSON解析失败: ' + e.message));
                    }
                }).fail(function() {
                    reject(new Error('API 请求失败'));
                });
            }).catch(function(err) {
                reject(err);
            });
        });
    }
    
    function encodeCode(cardIds, faction) {
        if (!Array.isArray(cardIds) || cardIds.length === 0) {
            throw new Error('cardIds 必须是非空数组');
        }
        
        if (!faction || !FACTION_CODE[faction]) {
            throw new Error('阵营参数无效，必须是"超弦体"或"晶源体"');
        }
        
        var prefix = PREFIX_BASE + '|' + FACTION_CODE[faction];
        
        // 将 cardId 转换为 index
        var indices = [];
        for (var i = 0; i < cardIds.length; i++) {
            var cardId = String(cardIds[i]).trim();
            var index = cardIdToIndexMap[cardId];
            if (typeof index === 'number') {
                indices.push(index);
            } else {
                console.warn('未找到 cardId 对应的 index:', cardId);
            }
        }
        
        if (indices.length === 0) {
            throw new Error('没有有效的卡牌index');
        }
        
        // 计算位掩码
        // 由于JavaScript位运算只支持32位，需要手动处理大整数
        // 找出最大的index，确定需要多少个十六进制字符
        var maxIndex = Math.max.apply(Math, indices);
        var minHexLen = Math.ceil((maxIndex + 1) / 4);
        var actualHexLen = Math.max(minHexLen, HEX_LEN);
        
        // 创建一个数组来存储每个十六进制字符（每个字符代表4位）
        var hexArray = new Array(actualHexLen);
        for (var i = 0; i < actualHexLen; i++) {
            hexArray[i] = 0;
        }
        
        // 对每个index，设置对应的位
        for (var i = 0; i < indices.length; i++) {
            var index = indices[i];
            // 计算该位在哪个十六进制字符中（从右往左）
            var hexPos = Math.floor(index / 4);
            // 计算在该十六进制字符的哪一位（0-3）
            var bitInHex = index % 4;
            // 设置该位
            hexArray[actualHexLen - 1 - hexPos] |= (1 << bitInHex);
        }
        
        // 将数组转换为十六进制字符串
        var hexStr = '';
        for (var i = 0; i < actualHexLen; i++) {
            hexStr += hexArray[i].toString(16).toUpperCase();
        }
        
        // 构造明文完整字符串
        var rawText = prefix + '|' + hexStr;
        
        // Base64编码
        var b64Str = btoa(unescape(encodeURIComponent(rawText)));
        
        // 加上 ** 后缀
        return b64Str + '**';
    }
    
    function decodeCode(fullCode, expectedFaction) {
        if (!fullCode || typeof fullCode !== 'string') {
            throw new Error('分享码不能为空');
        }
        
        if (!expectedFaction || !FACTION_CODE[expectedFaction]) {
            throw new Error('阵营参数无效，必须是"超弦体"或"晶源体"');
        }
        
        try {
            // 移除末尾的 **
            var b64Input = fullCode.endsWith('**') ? fullCode.slice(0, -2) : fullCode;
            
            // Base64解码回明文字符串
            var rawText = decodeURIComponent(escape(atob(b64Input)));
            
            // 按照 | 分割
            var parts = rawText.split('|');
            if (parts.length < 3) {
                throw new Error('解析错误：格式段落不足');
            }
            
            // 验证阵营代码
            var factionCode = parts[1];
            var decodedFaction = null;
            for (var key in FACTION_CODE) {
                if (FACTION_CODE[key] === factionCode) {
                    decodedFaction = key;
                    break;
                }
            }
            
            if (!decodedFaction) {
                alert('分享码中的阵营代码无效: ' + factionCode);
                return [];
            }
            
            // 检查阵营是否匹配
            if (decodedFaction !== expectedFaction) {
                alert('阵营不匹配！分享码是"' + decodedFaction + '"阵营，但当前选择的是"' + expectedFaction + '"阵营。');
                return [];
            }
            
            // 提取十六进制部分并转为整数
            var hexPart = parts[2];
            
            // 位运算提取下标
            // 由于JavaScript位运算只支持32位，需要手动处理大整数
            var indices = [];
            
            // 从右往左处理十六进制字符串，每次处理一个字符
            for (var i = hexPart.length - 1; i >= 0; i--) {
                var hexChar = hexPart[i];
                var value = parseInt(hexChar, 16);
                
                // 每个十六进制字符代表4位
                var baseBitPos = (hexPart.length - 1 - i) * 4;
                
                // 检查这4位中哪些位是1
                for (var bit = 0; bit < 4; bit++) {
                    if (value & (1 << bit)) {
                        indices.push(baseBitPos + bit);
                    }
                }
            }
            
            // 将 index 转换为 cardId
            var cardIds = [];
            for (var i = 0; i < indices.length; i++) {
                var cardId = indexToCardIdMap[indices[i]];
                if (cardId) {
                    cardIds.push(cardId);
                } else {
                    console.warn('未找到 index 对应的 cardId:', indices[i]);
                }
            }
            
            return cardIds;
        } catch (e) {
            alert('解析失败: ' + e.message);
            return [];
        }
    }
    
    // 初始化：加载卡牌数据
    loadCardData().then(function() {
        console.log('DeckSharecode: 卡牌数据加载完成');
        console.log('cardId->index 映射数量:', Object.keys(cardIdToIndexMap).length);
        console.log('index->cardId 映射数量:', Object.keys(indexToCardIdMap).length);
    }).catch(function(e) {
        console.error('DeckSharecode: 卡牌数据加载失败', e);
    });
    
    // 导出到全局
    window.encodeCode = encodeCode;
    window.decodeCode = decodeCode;
    
    console.log('DeckSharecode.js 已加载');
})();