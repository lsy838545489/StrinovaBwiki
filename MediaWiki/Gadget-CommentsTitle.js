"use strict";
(function () {
    var initCommentsTitle = function () {
        var rawPageName = mw.config.get('wgPageName');
        if (!rawPageName) return;
        var pageName = rawPageName.replace(/_/g, ' '); 
        
        // 处理子页面情况：通过斜杠分割，取第一个元素即为父页面名称
        var parentPageName = pageName.split('/')[0];

        // 定义固定的页面映射表 (键名：父页面名称，键值：固定文案)
        var fixedMap = {
            "令": "令的手工俱乐部",
            "香奈美": "香奈美的粉丝团",
            "芙拉薇娅": "芙拉薇娅的围棋室",
            "加拉蒂亚·利里": "加拉蒂亚的魔术团",
            "玛德蕾娜·利里": "玛德蕾娜的绘梦室",
            "米雪儿·李": "米雪儿的猫猫军团",
            "绯莎": "绯莎的秘训基地",
            "伊薇特": "伊薇特的小熊团",
            "信": "信的侦探推理社",
            "奥黛丽·格罗夫": "奥黛丽的执事团",
            "明": "明的暗影刺客团",
            "梅瑞狄斯": "梅瑞狄斯科考团",
            "星绘": "星绘的疗愈小屋",
            "拉薇": "拉薇的茗香茶社",
            "艾卡": "艾卡的吉他室",
            "心夏": "心夏的无人机小队",
            "白墨": "白墨的涂鸦社",
            "珐格兰丝": "珐格兰丝的植物园",
            "忧雾": "忧雾的图书角",
            "蕾欧娜": "蕾欧娜的工程部",
            "玛拉": "玛拉的特训场",
            "千代": "千代的弓道部",
            "汐": "汐的高塔小花园",
            "诺诺": "诺诺的咒术练习室",
            "空间实验室": "S12基地",
            "风曳镇": "斯崔恩曳风区"
        };

        // 定义随机池（没有匹配到固定名称时使用）
        var randomTitles = [
        	"甜梦游乐园",
        	"大喵电玩",
        	"翠景茶室",
        	"格罗夫银行大厦",
        	"欧泊警署",
        	"星庇所",
        	"回味时光咖啡厅",
        	"握爪起誓咖啡厅",
        	"白芸艺术馆",
        	"纽特朗88区",
        	"艾顿城星光大道",
        	"艾顿城云顶花园",
        	"普雷顿西铁区",
        	"普雷顿东丹区",
            "伊莱特隆大学城",
            "埃利蒙德5区",
            "埃利蒙德3区",
            "埃利蒙德2区"
        ];

        // 5. 判断并确定最终文案
        var finalTitle = "";
        if (fixedMap.hasOwnProperty(parentPageName)) {
            // 如果父页面在映射表中，使用固定文案
            finalTitle = fixedMap[parentPageName];
        } else {
            // 否则，随机抽取一个文案
            var randomIndex = Math.floor(Math.random() * randomTitles.length);
            finalTitle = randomTitles[randomIndex];
        }
        var titleElements = document.querySelectorAll('.comments-title');
        for (var i = 0; i < titleElements.length; i++) {
            titleElements[i].setAttribute('data-random-text', finalTitle);
        }
    };

    if (window.mw) {
        mw.hook('wikipage.content').add(function () {
            initCommentsTitle();
        });
    } else {
        // 本地测试或非 MediaWiki 环境的兜底兼容
        document.addEventListener('DOMContentLoaded', initCommentsTitle);
    }
})();