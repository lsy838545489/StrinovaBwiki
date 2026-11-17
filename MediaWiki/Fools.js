"use strict";
const u = {
    q: "e/e6/32msp0f5d5ezfiow6735bdd196r2e12",
    x: "4/4b/gn64arhmug3r5loh27yayuvdjyh1419",
    xm: "4/43/90kb9pew0jhynaxolv1cx3h83jiv41c",
};

// 预加载音频
Object.keys(u).forEach(k => {
    const a = new Audio(
        `https://patchwiki.biligame.com/images/klbq/${u[k]}.mp3`
    );
    u[k] = a;
});

// 标志变量：是否已触发过
let hasTriggered = false;

document.onkeydown = k => {
    if (hasTriggered) return; // 如果已经触发过，直接退出

    switch (k.key.toUpperCase()) {
        case "Q":
            new Audio(u.q.src).play();
            hasTriggered = true; // 标记为已触发
            break;
        case "X":
            new Audio(u.x.src).play();
            u.xm.play();
            hasTriggered = true; // 标记为已触发
            break;
    }
};

document.onclick = () => {
    if (hasTriggered) return; // 如果已经触发过，直接退出
    new Audio(u.q.src).play();
    hasTriggered = true; // 标记为已触发
};