/**
 * BWiki 自定义多选投票系统 - 结构化解析版
 */

(async function() {
    const poll_container = document.querySelector("#poll");
    if (!poll_container) return;

    // --- 1. 配置读取 ---
    const info_el = document.querySelector("#poll-info");
    const config = {};
    info_el.innerHTML.trim().split("\n").forEach(line => {
        if (line.includes("：")) {
            let [key, value] = line.split("：");
            config[key.trim()] = value.trim();
        }
    });

    const pageConfigName = config["名称"] || "投票";
    const limit = parseInt(config["限制票数"]) || 1;
    const targetDate = new Date(config["结束时间"]);
    const checkboxes = Array.from(document.querySelectorAll('#poll input[type="checkbox"]'));
    const roleList = checkboxes.map(cb => cb.value);

    let pollMapping = {}; 
    let totalParticipants = 0; 
    let totalPollId = "";
    let userInitiallyVotedTotal = false; 
    const api = new mw.Api();

    // --- 2. 核心初始化 ---
    async function initVoteData() {
        const nativeContainers = document.querySelectorAll('[id^="ajaxpoll-container-"]');
        nativeContainers.forEach(pollEl => {
            const questionEl = pollEl.querySelector('.ajaxpoll-question');
            if (!questionEl) return;
            
            const question = questionEl.innerText;
            const pollId = pollEl.querySelector('.ajaxpoll-id-info').innerText.replace('poll-id ', '').trim();
            
            roleList.forEach(role => {
                if (question.includes(`${pageConfigName}-${role}`)) {
                    pollMapping[role] = extractDataFromEl(pollEl, pollId);
                }
            });

            if (question.includes(`${pageConfigName}-总计锚点`)) {
                totalPollId = pollId;
                const data = extractDataFromEl(pollEl, pollId);
                totalParticipants = data.votes;
                userInitiallyVotedTotal = data.userVoted;
            }
        });

        const missingRoles = roleList.filter(role => !pollMapping[role]);
        if (missingRoles.length > 0 || !totalPollId) {
            await fetchMissingData(missingRoles);
        }

        // 初始化勾选状态
        roleList.forEach(role => {
            const cb = document.getElementById(role);
            if (cb && pollMapping[role]) cb.checked = pollMapping[role].userVoted;
        });

        refreshDisplay();
        nativeContainers.forEach(el => el.remove());
        checkboxes.forEach(cb => cb.addEventListener('change', refreshDisplay));
    }

	function extractDataFromEl(el, id) {
	    const answerEl = el.querySelector('.ajaxpoll-answer[answer="1"]');
	    let votes = 0;
	    let hasVoted = false;
	
	    // 尝试获取硬核数据（已登录或有权限时）
	    if (answerEl) {
	        const voteSpan = answerEl.querySelector('.ajaxpoll-answer-vote span');
	        if (voteSpan) {
	            votes = parseInt(voteSpan.innerText.trim()) || 0;
	        }
	        hasVoted = answerEl.classList.contains('ajaxpoll-our-vote') || 
	                   (answerEl.querySelector('input[checked]') !== null);
	    }
	
	    // --- 兜底逻辑：针对未登录被拦截的情况 ---
	    if (votes === 0) {
	        const infoEl = el.querySelector('.ajaxpoll-info');
	        if (infoEl) {
	            const infoText = infoEl.innerText;
	            // 匹配“共有一人”、“共有12人”等格式
	            const match = infoText.match(/共有(\d+|一|二|三|零|.+?)人/);
	            if (match) {
	                const v = match[1];
	                // 简单处理中文数字
	                if (v === '一') votes = 1;
	                else if (v === '零') votes = 0;
	                else votes = parseInt(v) || 0;
	            }
	        }
	    }
	
	    return { id, votes, userVoted: hasVoted };
	}

    async function fetchMissingData(missingRoles) {
        let text = missingRoles.map(role => `<poll show-results-before-voting=1>\n${pageConfigName}-${role}\n投给TA\n</poll>`).join('\n');
        if (!totalPollId) text += `\n<poll show-results-before-voting=1>\n${pageConfigName}-总计锚点\n已参加\n</poll>`;

        const data = await api.get({ action: 'parse', text: text, prop: 'text', contentmodel: 'wikitext' });
        const tempDiv = document.createElement('div');
        tempDiv.innerHTML = data.parse.text['*'];
        const polls = Array.from(tempDiv.querySelectorAll('.ajaxpoll'));

        missingRoles.forEach((role, i) => {
            const pollEl = polls[i];
            const pollId = pollEl.querySelector('.ajaxpoll-id-info').innerText.replace('poll-id ', '').trim();
            pollMapping[role] = extractDataFromEl(pollEl, pollId);
        });

        if (!totalPollId) {
            const lastPoll = polls[polls.length - 1];
            totalPollId = lastPoll.querySelector('.ajaxpoll-id-info').innerText.replace('poll-id ', '').trim();
            const tData = extractDataFromEl(lastPoll, totalPollId);
            totalParticipants = tData.votes;
            userInitiallyVotedTotal = tData.userVoted;
        }
    }

    function refreshDisplay() {
        const currentSelected = checkboxes.filter(cb => cb.checked);
        let previewTotal = totalParticipants;
        if (!userInitiallyVotedTotal && currentSelected.length > 0) previewTotal += 1;
        else if (userInitiallyVotedTotal && currentSelected.length === 0) previewTotal -= 1;

        const titleEl = document.getElementById('tittleVote');
        if (titleEl) titleEl.innerText = `${pageConfigName}（当前参与人数：${previewTotal} 人）：`;

        roleList.forEach(role => {
            const cb = document.getElementById(role);
            const infoSpan = document.getElementById(`${role}-info`);
            const data = pollMapping[role];

            if (data && infoSpan) {
                let previewVotes = data.votes;
                if (cb.checked && !data.userVoted) previewVotes += 1;
                if (!cb.checked && data.userVoted) previewVotes -= 1;

                const rate = previewTotal > 0 ? ((previewVotes / previewTotal) * 100).toFixed(1) : 0;
                infoSpan.innerText = `支持人数：${previewVotes}（支持率 ${rate}%）`;
                infoSpan.style.color = (cb.checked !== data.userVoted) ? "#ff6600" : "";
            }
        });
    }

    async function uploadVoteInfo() {
        if (mw.config.get('wgUserId') === null) return alert("请先登录 Bilibili 后再参与投票！");
        if (new Date() > targetDate) return alert("投票已结束！");

        const selected = checkboxes.filter(cb => cb.checked);
        if (selected.length > limit) return alert(`最多只能选择 ${limit} 项！`);

        const btnText = document.querySelector('.submit-button-text');
        btnText.innerText = "正在提交选票...";
        const token = mw.user.tokens.get('csrfToken');
        const promises = [];

        roleList.forEach(role => {
            const cb = document.getElementById(role);
            const data = pollMapping[role];
            if (!data) return;
            if (cb.checked && !data.userVoted) promises.push(api.post({ action: 'pollsubmitvote', poll: data.id, answer: '1', token: token }));
            else if (!cb.checked && data.userVoted) promises.push(api.post({ action: 'pollsubmitvote', poll: data.id, answer: '0', token: token }));
        });

        if (selected.length > 0) promises.push(api.post({ action: 'pollsubmitvote', poll: totalPollId, answer: '1', token: token }));
        else if (userInitiallyVotedTotal && selected.length === 0) promises.push(api.post({ action: 'pollsubmitvote', poll: totalPollId, answer: '0', token: token }));

        try {
            await Promise.all(promises);
            btnText.innerText = "完成！";
            location.reload();
        } catch (err) { btnText.innerText = "提交失败。"; }
    }

    const submitBtn = document.querySelector('.submit-button');
    if (new Date() > targetDate) submitBtn.style.display = 'none';
    else submitBtn.addEventListener('click', uploadVoteInfo);

    await initVoteData();
})();