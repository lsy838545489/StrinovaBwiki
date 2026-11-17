// ==========================================
// 自定义多选投票系统
// ==========================================

mw.loader.using(['mediawiki.api', 'mediawiki.user']).then(async function() {
    console.log("[CustomPoll] 脚本已成功载入，开始扫描页面投票组件...");
    const containers = document.querySelectorAll(".kqp-poll-container");
    if (containers.length === 0) return;

    const api = new mw.Api();

    for (const container of containers) {
        const info_el = container.querySelector(".poll-info");
        if (!info_el) continue;
        
        const config = {};
        // 兼容全角“：”和半角“:”以防手误
        info_el.textContent.trim().split("\n").forEach(line => {
            if (line.includes("：") || line.includes(":")) {
                let separator = line.includes("：") ? "：" : ":";
                let [key, ...values] = line.split(separator);
                config[key.trim()] = values.join(separator).trim();
            }
        });

        const pageConfigName = config["名称"] || "未命名投票";
        const limit = parseInt(config["限制票数"]) || 1;
        const targetDate = new Date(config["结束时间"]);
        const checkboxes = Array.from(container.querySelectorAll('input[type="checkbox"]'));
        const roleList = checkboxes.map(cb => cb.value);

        console.log(`[CustomPoll] 配置读取成功 -> 名称: ${pageConfigName}, 限制票数: ${limit}`);

        let pollMapping = {}; 
        let totalParticipants = 0; 
        let totalPollId = "";
        let userInitiallyVotedTotal = false; 

        async function initVoteData() {
            try {
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
                    console.log(`[CustomPoll] 存在 ${missingRoles.length} 个未建立的锚点，尝试向服务器请求...`);
                    await fetchMissingData(missingRoles);
                }

                roleList.forEach(role => {
                    const cb = container.querySelector(`input[value="${role}"]`);
                    if (cb && pollMapping[role]) cb.checked = pollMapping[role].userVoted;
                });

                refreshDisplay();
                document.querySelectorAll('[id^="ajaxpoll-container-"]').forEach(el => el.remove());
                checkboxes.forEach(cb => {
    				cb.addEventListener('change', (e) => {
        				// 当限制票数为 1 且当前勾选了该项时，自动取消其他已勾选项
        				if (limit === 1 && e.target.checked) {
            				checkboxes.forEach(other => {
                				if (other !== e.target) other.checked = false;
            				});
        				}
        				refreshDisplay();
    				});
				});
                
            } catch (error) {
                console.error("[CustomPoll] 初始化遭遇严重错误:", error);
                container.querySelectorAll('.poll-info-text').forEach(el => el.innerText = "数据解析失败");
            }
        }

        function extractDataFromEl(el, id) {
            const answerEl = el.querySelector('.ajaxpoll-answer[answer="1"]');
            let votes = 0; let hasVoted = false;
        
            if (answerEl) {
                const voteSpan = answerEl.querySelector('.ajaxpoll-answer-vote span');
                if (voteSpan) votes = parseInt(voteSpan.innerText.trim()) || 0;
                hasVoted = answerEl.classList.contains('ajaxpoll-our-vote') || (answerEl.querySelector('input[checked]') !== null);
            }
        
            if (votes === 0) {
                const infoEl = el.querySelector('.ajaxpoll-info');
                if (infoEl) {
                    const match = infoEl.innerText.match(/共有(\d+|一|二|三|零|.+?)人/);
                    if (match) {
                        const v = match[1];
                        if (v === '一') votes = 1; else if (v === '零') votes = 0; else votes = parseInt(v) || 0;
                    }
                }
            }
            return { id, votes, userVoted: hasVoted };
        }

        async function fetchMissingData(missingRoles) {
            let text = missingRoles.map(role => `<poll show-results-before-voting=1>\n${pageConfigName}-${role}\n投给TA\n</poll>`).join('\n');
            if (!totalPollId) text += `\n<poll show-results-before-voting=1>\n${pageConfigName}-总计锚点\n已参加\n</poll>`;

            const data = await api.get({ action: 'parse', text: text, prop: 'text', contentmodel: 'wikitext', disablelimitreport: true });
            const tempDiv = document.createElement('div');
            tempDiv.innerHTML = data.parse.text['*'];
            const polls = Array.from(tempDiv.querySelectorAll('.ajaxpoll'));

            // 深度容错：如果服务器没有返回预期的组件
            if (polls.length === 0) {
                console.error("[CustomPoll] 服务器未能成功解析 <poll> 标签！返回的原始内容如下：", data.parse.text['*']);
                throw new Error("Wikitext解析被服务器拦截或扩展未生效");
            }

            missingRoles.forEach((role, i) => {
                const pollEl = polls[i];
                if(pollEl) {
                    const pollIdEl = pollEl.querySelector('.ajaxpoll-id-info');
                    if (pollIdEl) {
                        const pollId = pollIdEl.innerText.replace('poll-id ', '').trim();
                        pollMapping[role] = extractDataFromEl(pollEl, pollId);
                    }
                }
            });

            if (!totalPollId) {
                const lastPoll = polls[polls.length - 1];
                if (lastPoll) {
                    const lastPollIdEl = lastPoll.querySelector('.ajaxpoll-id-info');
                    if(lastPollIdEl) {
                        totalPollId = lastPollIdEl.innerText.replace('poll-id ', '').trim();
                        const tData = extractDataFromEl(lastPoll, totalPollId);
                        totalParticipants = tData.votes;
                        userInitiallyVotedTotal = tData.userVoted;
                    }
                }
            }
        }

        function refreshDisplay() {
            const currentSelected = checkboxes.filter(cb => cb.checked);
            let previewTotal = totalParticipants;
            if (!userInitiallyVotedTotal && currentSelected.length > 0) previewTotal += 1;
            else if (userInitiallyVotedTotal && currentSelected.length === 0) previewTotal -= 1;

            const titleEl = container.querySelector('.tittleVote');
            if (titleEl) titleEl.innerText = `累计投票人数：${previewTotal}`;

            roleList.forEach(role => {
                const cb = container.querySelector(`input[value="${role}"]`);
                const infoSpan = container.querySelector(`.poll-info-text[data-role="${role}"]`);
                const data = pollMapping[role];

                if (data && infoSpan) {
                    let previewVotes = data.votes;
                    if (cb.checked && !data.userVoted) previewVotes += 1;
                    if (!cb.checked && data.userVoted) previewVotes -= 1;

                    const rate = previewTotal > 0 ? ((previewVotes / previewTotal) * 100).toFixed(1) : 0;
                    infoSpan.innerText = `支持人数：${previewVotes}（支持率 ${rate}%）`;
                    infoSpan.style.color = (cb.checked !== data.userVoted) ? "#60a5fa" : "#64748b";
                }
            });
        }

        async function uploadVoteInfo() {
            console.log("[CustomPoll] 提交按钮被点击！");
            if (mw.config.get('wgUserId') === null) return alert("请先登录后再参与投票！");
            // 兼容 Date 校验失败的情况
            if (targetDate.toString() !== "Invalid Date" && new Date() > targetDate) return alert("投票已结束！");

            const selected = checkboxes.filter(cb => cb.checked);
            if (selected.length > limit) return alert(`最多只能选择 ${limit} 项！\n你当前选择了 ${selected.length} 项。`);

            const btnText = container.querySelector('.submit-button-text');
            btnText.innerText = "正在提交选票...";
            const token = mw.user.tokens.get('csrfToken');
            const promises = [];

            roleList.forEach(role => {
                const cb = container.querySelector(`input[value="${role}"]`);
                const data = pollMapping[role];
                if (!data) return;
                
                if (cb.checked && !data.userVoted) promises.push(api.post({ action: 'pollsubmitvote', poll: data.id, answer: '1', token: token }));
                else if (!cb.checked && data.userVoted) promises.push(api.post({ action: 'pollsubmitvote', poll: data.id, answer: '0', token: token }));
            });

            if (selected.length > 0) promises.push(api.post({ action: 'pollsubmitvote', poll: totalPollId, answer: '1', token: token }));
            else if (userInitiallyVotedTotal && selected.length === 0) promises.push(api.post({ action: 'pollsubmitvote', poll: totalPollId, answer: '0', token: token }));

            // 如果用户什么都没改就点提交，直接拦截避免无效请求
            if (promises.length === 0) {
                btnText.innerText = "完成！";
                setTimeout(() => { btnText.innerText = "提交投票"; }, 1500);
                return;
            }

            try {
                await Promise.all(promises);
                btnText.innerText = "提交成功！";

                const easterEggEl = container.querySelector('.poll-easter-egg');
                let easterEggItems = [];
                
                if (easterEggEl && easterEggEl.innerHTML.trim()) {
                    easterEggItems = easterEggEl.innerHTML.trim().split("\n")
                        .map(q => q.trim())
                        .filter(q => q.length > 0);
                }

                if (easterEggItems.length > 0) {
                    const randomItem = easterEggItems[Math.floor(Math.random() * easterEggItems.length)];
                    const dialog = document.createElement('div');
                    
                    // 获取提交按钮的父容器
                    const submitWrap = container.querySelector('.poll-submit-wrap');
                    submitWrap.style.position = 'relative';

                    dialog.innerHTML = `
                        <div style="display: flex; flex-direction: column; gap: 10px; position: relative; z-index: 2;">
                            <div style="color: #475569; font-size: 14px; line-height: 1.5; font-weight: bold; text-align: center; display: flex; justify-content: center; align-items: center; min-height: 60px;">
                                ${randomItem}
                            </div>
                        </div>
                        <div style="position: absolute; bottom: -6px; left: 50%; transform: translateX(-50%) rotate(45deg); width: 12px; height: 12px; background: rgba(248, 249, 250, 0.95); border-right: 1px solid rgba(147, 197, 253, 0.5); border-bottom: 1px solid rgba(147, 197, 253, 0.5); z-index: 1;"></div>
                    `;
                    
                    Object.assign(dialog.style, {
                        position: 'absolute',
                        bottom: '100%',
                        left: '50%',
                        marginBottom: '16px',
                        width: 'max-content',
                        maxWidth: '300px',
                        background: 'rgba(248, 249, 250, 0.95)', 
                        border: '1px solid rgba(147, 197, 253, 0.5)',
                        borderRadius: '12px', 
                        padding: '16px 20px',
                        boxShadow: '0 8px 24px rgba(59, 130, 246, 0.15)', 
                        backdropFilter: 'blur(8px)',
                        zIndex: '9999', 
                        pointerEvents: 'none',
                        transform: 'translate(-50%, 15px)', 
                        opacity: '0',
                        transition: 'all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1)'
                    });
                    
                    submitWrap.appendChild(dialog);

                    // 动画 1：向上浮动并显现
                    requestAnimationFrame(() => { 
                        requestAnimationFrame(() => { 
                            dialog.style.transform = 'translate(-50%, 0)'; 
                            dialog.style.opacity = '1'; 
                        }); 
                    });
                    setTimeout(() => {
                        dialog.style.opacity = '0'; 
                        dialog.style.transform = 'translate(-50%, -15px)';
                        setTimeout(() => location.reload(), 300);
                    }, 2000);
                } else {
                    location.reload();
                }

            } catch (err) { 
                btnText.innerText = "提交失败"; 
                console.error("[CustomPoll] 提交 API 报错: ", err);
            }
        }

        const submitBtn = container.querySelector('.submit-button');
        if (targetDate.toString() !== "Invalid Date" && new Date() > targetDate) {
            submitBtn.style.display = 'none';
        } else {
            submitBtn.addEventListener('click', (e) => {
                e.preventDefault();
                uploadVoteInfo();
            });
        }

        await initVoteData();
    }
});