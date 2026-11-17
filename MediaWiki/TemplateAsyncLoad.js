/* zh.moegirl.org.cn/Widget:TemplateAsyncLoad */

(async () => {
    await mw.loader.using(["mediawiki.page.ready", "mediawiki.api"]);
    const { wgPageName, skin, wgUserVariant, wgFormattedNamespaces } = mw.config.get(["wgPageName", "skin", "wgUserVariant", "wgFormattedNamespaces"]);
    const prefix = new RegExp(`^${wgFormattedNamespaces[10]}:`);
    const api = new mw.Api();

    const load = async (ele) => {
        if (ele.classList.contains("loading")) {
            return;
        }
        ele.classList.add("loading");
        const { title } = ele.dataset;
        if (typeof title !== "string" || !prefix.test(title)) {
            console.info("[widget:TemplateAsyncLoad]", `[${title}]`, "invalid title, skip.");
            return;
        }
        const wrapoutputclass = `TemplateAsyncLoad-${crypto.randomUUID()}`;
        const params = [];
        for (const keyIndex of Object.keys(ele.dataset)) {
            if (!/^key-[1-9]\d*$/.test(keyIndex)) {
                continue;
            }
            const valueIndex = keyIndex.replace(/^key-/, "value-");
            if (!Reflect.has(ele.dataset, valueIndex)) {
                continue;
            }
            const key = ele.dataset[keyIndex]?.replaceAll("|", "{{!}}");
            const value = ele.dataset[valueIndex]?.replaceAll("|", "{{!}}");
            console.info("[widget:TemplateAsyncLoad]", `[${title}]`, "param:", { key, value });
            params.push(`|${key}=${value}`);
        }
        for (let i = 0; i < 3; i++) {
            console.info("[widget:TemplateAsyncLoad]", `[${title}]`, "loading #", i);
            try {
                const output = new DOMParser().parseFromString((await api.post({
                    action: "parse",
                    title: wgPageName,
                    text: `{{${title}${params.join("")}}}`,
                    prop: "text",
                    formatversion: 2,
                    wrapoutputclass,
                    disablelimitreport: true,
                    disableeditsection: true,
                    pst: true,
                    disabletoc: true,
                    useskin: skin,
                    variant: wgUserVariant,
                }))?.parse?.text || `<div class="${wrapoutputclass}">${wgULS("无内容=。=")}</div>`, "text/html").getElementsByClassName(wrapoutputclass)[0];
                if (output.children.length === 1 && output.children[0].tagName === "P" && output.children[0].attributes.length === 0) {
                    output.innerHTML = output.children[0].innerHTML;
                }
                output.classList.add("mw-parser-output", "templateAsyncLoadRoot");
                ele.after(output);
                ele.style.display = "none";
                mw.hook("wikipage.content").fire(output);
                return;
            } catch (e) {
                console.error("[widget:TemplateAsyncLoad]", `[${title}]`, "error #", i, e);
                if (i >= 2) {
                    ele.removeAttribute("style");
                    const pre = document.createElement("pre");
                    pre.innerText = `异步模板加载发生错误：${typeof e === "string" ? e : e instanceof Error ? `${e}${e.stack ? ` @ ${e.stack}}` : ""}` : JSON.stringify(e)}`;
                    ele.innerHTML = "";
                    ele.append(pre);
                }
            }
        }
    };

    const lazyLoadObserver = new IntersectionObserver((entries) => {
        for (const entry of entries) {
            if (entry.isIntersecting) {
                const lazyTarget = entry.target;
                load(lazyTarget);
                lazyLoadObserver.unobserve(lazyTarget);
            }
        }
    });

    for (const ele of [...document.querySelectorAll(".TemplateAsyncLoad")]) {
        lazyLoadObserver.observe(ele);
    }
})();