// <pre>

"use strict";

RLQ.push(() => {
	const options = [
		"WASD",
		"卡拉彼丘是一个多维空间，人类在此获得了进化，被称为卡丘人。",
		"超弦体是适应了争斗，不断进化并掌握了特殊能力的个体称呼。",
		"如果你还有梦想，去追逐吧，卡丘世界能够实现你的一切梦想！",
		"侧身，在战斗中能有效躲避正面的子弹。",
		"卡丘世界即人类在卡丘空间中生活的世界，构成这个世界的主要能源是弦能。",
		"当队友倒地时，尽快去支援他，救他。",
		"巴布洛晶体是弦能的载体，它们随机地分散在真实荒野之中，是目前人类已知的最强能源。",
		"崩溃症的表现有心智丧失，狂躁等表现，对于医治该疾病，各方都在提出自己的意见。",
		"卡丘世界拥有很多奇迹，相信自己就是奇迹。",
		"和狙击手作战时如果距离远最好优先寻找掩体，确保安全的情况下尽可能贴近对方再发起进攻。",
		"炸弹起爆需要时间，确保防守方试图拆除炸弹时你能尽快阻止。",
		"留意身后，敌人不只会出现在前方。",
		"不要试图穿过正在倾泻火力的奥黛丽的封锁线，除非你不得不这么做。",
		"瞄准敌人时注意前方的队友，不要站在一条线上，他/她不是敌人。",
		"在队友打算潜伏时，请不要在队友附近吸引火力。",
		"弦化后的机动性很高，善用会有高光表现噢！",
		"当一个地方久攻不下时，尝试与队友沟通更换进攻目标或许是更好的选择。",
		"星绘很喜欢咖啡，她希望借由醇厚的芳香此驱赶内心的迷茫。",
		"星绘在面对不听话的患者时还是会露出生气的表情的。",
		"星绘调配的咖啡每天都会加入些许变化，以至于已经迭代了不知道多少个版本。",
		"虽然与你的遭遇只是偶然，但对于星绘来说，这是她值得珍视的必然。",
		"历经无数个夜晚的观测与守候，星空会回应她吗？",
		"医者不能自医，星绘在治疗他人的时候，也需要一个医生来治疗她。",
		"她所点亮的星星，会成为后来者前进的道路。",
		"作为星庇所的负责人，她被所有医护人员敬仰，但她依旧保持谦卑善良。",
		"你可以永远相信星绘，她也会永远相信你。",
		"米雪儿是个狂热的游戏玩家，保持着多项游戏的世界纪录。",
		"米雪儿最喜欢的生物是猫，虽然暂时还没有养过真正的猫。",
		"无数个辗转反侧的夜晚，米雪儿都在问自己，什么才是正义呢？",
		"父亲是米雪儿最好的榜样，是她前进的方向。",
		"米雪儿经常因出乎预料的行动而胜利，但也因为违反纪律而经常写检讨。",
		"火力大喵是父亲留给她的伙伴，也是她内心的坚强支柱。",
		"米雪儿不喜欢SOLO，所以她总希望有个伙伴能陪同她一起冒险。",
		"奥黛丽经历过崩溃症，但她还是借由周遭他人的帮助和自己的日记，重新拼凑出了自己。",
		"奥黛丽身上的王冠，是家族的象征物，坚硬光耀的外表包裹了柔软纯粹的内核，诠释着“家族”的含义。",
		"奥黛丽总是喜欢把家族挂在嘴边。",
		"她总能理智地分析形势，冷静面对事态的各种变化，但是被夸奖的时候，她的脸红早已暴露了一切。",
		"奥黛丽的火力和她冷彻的头脑是她最大的武器。",
		"重火倾泄的身后，是值得信任的队友，是需要保护的信念。",
		"奥黛丽作为一个资本家似乎还不够成熟，她仍然拥有着名为慈爱的弱点。",
		"踏上战场也是一种工作，奥黛丽如此坚信着。",
		"拉薇是一个出色的武道家，这和她小时候的经历有关。",
		"拉薇的心思缜密，因此才能成为剪刀手的执行者。",
		"拉薇有品茶的爱好，尤其是对绿茶尤其钟爱。",
		"拉薇与冲动的明有着明显的互补关系，在战场上她们能够充分调动队员们的战斗意志。",
		"拉薇曾经是欧泊搜查官中数一数二的好手，本应拥有无限的未来。",
		"拉薇握紧手中的脉冲刀，她告诉自己将与过去诀别，那把利刃在黑夜中显露锋芒。",
		"拉薇经常通过武道来砥砺自己的内心，驱散自己的迷茫。",
		"心夏自称保持旺盛精力的秘诀是多多微笑。",
		"心夏的治疗无人机是她在大学时期与朋友们创造出来的杰作。",
		"玛德蕾娜的世界非常简单——创造美妙的艺术，让大家享受这个全新的世界。",
		"明瞳孔中的火焰从未熄灭，年幼的她握紧双拳保护弱者，现在的她把枪口对准压迫者。",
		"当你使用明开大招时，记得时刻保持你的临时护甲存在，这样大招就会一直存在。",
		"在夜深人静时，令的脸上总会浮现出一丝温柔。",
		"信每天都会被疼痛惊醒，这份疼痛来自于血亲的背叛。",
		"注意到了吗？信和令的在专注狙击时会触发被动。",
		"白墨最好的朋友送给他一个涂鸦喷漆罐，他用它在真实荒野中一次次留下自己的印记，承载着回忆与自由。",
		"白墨的主动技是以弦化形态进行位移，所以禁弦化的技能可让白墨主动技短暂无法使用。",
		"“这是从我的灵魂中发出的歌声，也是我想要献给世界的礼物♪”——香奈美。",
		"伊薇特熟悉各种生物，并帮助它们在卡丘世界存活下去。",
	];
	const leftPic = document.body.getElementsByClassName("leftPic")[0];
	const leftPicImg = leftPic
		.getElementsByClassName("picIn")[0]
		.getElementsByTagName("img")[0];
	const lineText = leftPic.getElementsByClassName("lineText")[0];
	let leftPicClick = 0;
	leftPic.onclick = () => {
		leftPicClick++;
		let text;
		if (
			[10, 50, 100, 101, 102, 1000, 1001, 10000, Infinity].includes(
				leftPicClick,
			)
		) {
			lineText.style.backgroundColor = "lightyellow";
		} else {
			lineText.style.backgroundColor = "#FFF";
		}
		switch (leftPicClick) {
			case 10:
				text = "你好无聊";
				break;
			case 50:
				text = "你在干什么";
				break;
			case 100:
				text = "？";
				break;
			case 101:
				text = "没有彩蛋了，别再点了";
				break;
			case 102:
				text = "真没了，别点了";
				break;
			case 1000:
				text = "毅力惊人";
				break;
			case 1001:
				text = "不！许！再！点！了！";
				leftPicImg.style.opacity = 0;
				break;
			case 10000:
				text = "啊？";
				break;
			case Infinity:
				text = "\u8BF7\u52FF\u5077\u770B\u6E90\u4EE3\u7801";
				break;
			default:
				text = options[Math.floor(Math.random() * options.length)];
				break;
		}
		lineText.innerText = text;
		lineText.style.opacity = 1;
		lineText.style.display = "";
		const curClick = leftPicClick;
		setTimeout(
			() => {
				if (curClick === leftPicClick) {
					lineText.style.opacity = 0;
					setTimeout(() => {
						if (curClick === leftPicClick)
							lineText.style.display = "none";
					}, 350);
				}
			},
			text.length * 100 + 1000,
		);
		leftPicImg.style.transform = Math.round(Math.random())
			? `rotate(${Math.round(Math.random() * 6) * 90 - 270}deg)`
			: `scale${
					Math.round(Math.random() * 2)
						? Math.round(Math.random())
							? "X"
							: "Y"
						: ""
				}(${Math.round(Math.random()) ? "" : "-"}${Math.round(
					Math.random(),
				)}.5)`;
	};
	let [x, y] = [0, 0];
	document.addEventListener("keydown", e => {
		switch (e.key) {
			case "w":
				y -= 1;
				break;
			case "s":
				y += 1;
				break;
			case "a":
				x -= 1;
				break;
			case "d":
				x += 1;
				break;
		}
		requestAnimationFrame(() => {
			leftPic.style.translate = `${x * 5}vmin ${y * 5}vmin`;
		});
	});
});

// </pre>