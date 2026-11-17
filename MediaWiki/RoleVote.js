// console.log(UserStatus.userInfo.mid)
const url_api = "https://wiki.biligame.com/klbq/api.php";
// 参考了https://wiki.biligame.com/tools/MediaWiki:Bikit-collection.js
// https://wiki.biligame.com/tools/index.php?title=widget:WIKIconfig


/**
 * 获取 mw api 需要的 csrf token
 * API文档： https://wiki.biligame.com/data/api.php?action=help&modules=query%2Btokens
 * @returns {Promise}
 */
function get_token() {
	return new Promise((resolve, reject) => {
		let url = url_api + '?' + new URLSearchParams({
			action: 'query',
			meta: 'tokens',
			format: 'json',
		});

		fetch(url, ).then(response => {
				if (!response.ok) {
					throw Error(response.statusText)
				}
				return response.json()
			})
			.then(data => resolve(data.query.tokens.csrftoken))
			.catch(error => reject(error));
	});
}

/**
 * 向 data wiki 缓存信息
 * @param page 完整页面名
 * @param save_str 字符串，要存储的
 * @returns {Promise<unknown>}
 */
function save(page, save_str) {
	return new Promise((resolve, reject) => {
		get_token().then((token) => {
			let save_param = {
				title: page,
				text: save_str,
				summary: "角色人气投票自动化更新数据",
				bot: true,
				token: token,
				action: "edit",
				format: 'json',
			};
			// request api
			fetch(url_api, {
				method: 'POST',
				body: to_form_data(save_param),
			}).then(response => {
				if (!response.ok) {
					reject("Http state error: " + response.statusText);
				}
				return response.json(); // it is a promise, not json
			}).then(data => {
				if (data.error) {
					reject("page edit fail '" + page + "'. error info: " + data.error.code +
						": " + data.error.info)
				} else {
					resolve(data);
				}
			}).catch(error => {
				// 如果json解析出错也会到这里处理
				reject("edit page error: " + error);
			});
		}).catch((e) => {
			reject("can not get token. " + e);
		})
	});
}

/**
 * obj to http form_data
 * @param data
 * @returns {FormData}
 */
function to_form_data(data) {
	let form_data = new FormData();
	for (let key in data) {
		form_data.append(key, data[key]);
	}
	return form_data;
}


function getUserID() {
	return UserStatus.userInfo.mid;
}


function uniqueArr(arr) {
	var newArr = [];
	for (var i = 0; i < arr.length; i++) {
		if (newArr.indexOf(arr[i]) === -1) {
			newArr.push(arr[i]);
		}
	}
	return newArr;
}

let voteInfo = {};
let playerList = []
let voteCount = 0;
let hasLoadInfo = false;
let info = document.querySelector("#poll-info").innerHTML.trim();

const config = {};
let lines = info.split("\n");
lines.forEach(line => {
	if (line.includes("：")) {
		let [key, value] = line.split("：");
		config[key.trim()] = value.trim();
	}
});
console.log(JSON.stringify(config, null, 2));

const limit = config["限制票数"];
const targetDate = new Date(config["结束时间"]);
const currentDate = new Date();

const pageName = config["名称"];

function loadVoteInfo() {
	//先初始化一个库
	let nb = new NBASE()

	//读取加密数据
	let option = {
		pwd: "klbq"
	}
	nb.read(pageName, option).then((result) => {
		// console.log(result) //保存的内容
		voteInfo = JSON.parse(result);
		for (let i in voteInfo) {
			playerList = playerList.concat(voteInfo[i]);
			// voteCount+=voteInfo[i].length;
		}
		playerList = uniqueArr(playerList);
		voteCount = playerList.length;

		console.log(voteCount);
		if (document.getElementById('tittleVote') != null) {
			document.getElementById('tittleVote').innerText += "（目前已经有" + voteCount + "人参加）：";
		}
		const checkboxes = document.querySelectorAll('input[type="checkbox"]');
		const labels = document.querySelectorAll('label');
		for (let i = 0; i < checkboxes.length; i++) {
			// 扩展不存在的选项
			if (voteInfo[checkboxes[i].value] == null)
				voteInfo[checkboxes[i].value] = [];

			if (voteInfo[checkboxes[i].value].indexOf(UserStatus.userInfo.mid) != -1) {
				labels[i].classList.add('selected');
				checkboxes[i].checked = true;

			} else {
				labels[i].classList.remove('selected');
				checkboxes[i].checked = false;
			}
			let voteNums = voteInfo[checkboxes[i].value].length;
			if (voteNums > 0) {
				document.getElementById(checkboxes[i].value + '-info').innerText = "投票人数：" + voteNums + "（占" +
					parseInt(parseFloat(voteNums * 100) / parseFloat(voteCount)) + "%）";
			}
		}
		hasLoadInfo = true;
	}).catch((result) => {
		console.log(result) //密码错误
		if (result.code == 201) {
			if (document.getElementById('tittleVote') != null) {
				document.getElementById('tittleVote').innerText += "（目前已经有" + voteCount + "人参加）：";
			}
			const checkboxes = document.querySelectorAll('input[type="checkbox"]');
			const labels = document.querySelectorAll('label');
			for (let i = 0; i < checkboxes.length; i++) {
				// 扩展不存在的选项
				voteInfo[checkboxes[i].value] = [];
				labels[i].classList.remove('selected');
				checkboxes[i].checked = false;
			}
			hasLoadInfo = true;
		}
	})

}

function quickDeleteElement(poollist, item) {
	let size = poollist.length;
	for (var j = 0; j < size; j++) {
		if (poollist[j] == item) {
			poollist.splice(j, 1);
			break;
		}
	}
	return poollist;
}

function addCurrentInfo(voteInfoObj) {
	const checkboxes = document.querySelectorAll('input[type="checkbox"]');
	const labels = document.querySelectorAll('label');
	countLimit = 0;
	for (let i = 0; i < checkboxes.length; i++) {
		if (voteInfoObj[checkboxes[i].value] == undefined) {
			voteInfoObj[checkboxes[i].value] = [];
		}
		if (checkboxes[i].checked) {
			if (voteInfoObj[checkboxes[i].value].indexOf(getUserID()) == -1) {
				voteInfoObj[checkboxes[i].value].push(getUserID());
				countLimit++;
			}
		} else {
			if (voteInfoObj[checkboxes[i].value].indexOf(getUserID()) != -1) {
				voteInfoObj[checkboxes[i].value] = quickDeleteElement(voteInfoObj[checkboxes[i].value],
					getUserID());
				countLimit++;
			}
		}
	}
	return countLimit;
}


function uploadVoteInfo() {
	if (currentDate > targetDate) {
		alert("投票已经结束！");
		return;
	}
	//先初始化一个库
	let nb = new NBASE()
	//为写入的数据加密
	let option = {
		pwd: "klbq"
	}
	let voteSelectCount = addCurrentInfo({});
	if (voteSelectCount > limit) {
		alert("限制票数为" + limit + "，目前为" + voteSelectCount);
		return;
	}
	nb.read(pageName, option).then((result) => {
		// console.log("最新:", result); //保存的内容
		voteInfo = JSON.parse(result);
		addCurrentInfo(voteInfo);
		nb.save(pageName, JSON.stringify(voteInfo),
				option).then(() => {
				console.log("写入成功！");
				// alert("投票成功！");			// location.reload(true);
				document.querySelector('.submit-button-text').innerText = "提交成功！";
				location.reload(true);
			})
			.catch(error => {
				alert("请先登录或更换网络条件！");
			})
		// alert("投票已经结束！");
	}).catch((result) => {
		console.log(result) //密码错误
		if (result.code == 201) {
			nb.save(pageName, JSON.stringify(voteInfo),
					option).then(() => {
					console.log("写入成功！");
					// alert("投票成功！");			// location.reload(true);
					document.querySelector('.submit-button-text').innerText = "提交成功！";
					location.reload(true);
				})
				.catch(error => {
					alert("请先登录或更换网络条件！");
				})
			// alert("投票已经结束！");
		}
	})

}


loadVoteInfo();
document.querySelector('.submit-button').addEventListener('click', function() {
	// 必须先确认已经加载完成了才能提交
	if (hasLoadInfo == true)
		uploadVoteInfo(); // 在这里写上提交事件的代码
});

if(currentDate > targetDate){
	document.querySelector('.submit-button').style.display='none'
}

function updateVoteForLocal() {
	const checkboxes = document.querySelectorAll('input[type="checkbox"]');
	const labels = document.querySelectorAll('label');
	for (let i = 0; i < checkboxes.length; i++) {
		let a = labels[i]
		a.addEventListener('click', function() {
			if (hasLoadInfo) {
				// console.log(checkboxes[i].checked);
				let realStatus = !checkboxes[i].checked;
				if (realStatus) {
					// if (voteInfo[checkboxes[i].value].indexOf(getUserID()) == -1)
					// 	{
					voteInfo[checkboxes[i].value].push(getUserID());
					voteInfo[checkboxes[i].value] = uniqueArr(voteInfo[checkboxes[i].value]);
					let voteNums = voteInfo[checkboxes[i].value].length;
					document.getElementById(checkboxes[i].value + '-info').innerText = "投票人数：" + voteNums +
						"（占" + parseInt(parseFloat(voteNums * 100) / parseFloat(voteCount > 0 ? voteCount :
							1)) + "%）";
					// }
				} else {
					// if (voteInfo[checkboxes[i].value].indexOf(getUserID()) != -1){
					voteInfo[checkboxes[i].value] = quickDeleteElement(voteInfo[checkboxes[i].value],
						getUserID())
					let voteNums = voteInfo[checkboxes[i].value].length;
					document.getElementById(checkboxes[i].value + '-info').innerText = "投票人数：" + voteNums +
						"（占" + parseInt(parseFloat(voteNums * 100) / parseFloat(voteCount > 0 ? voteCount :
							1)) + "%）";
					// }
				}
			}
		});
	}
}

updateVoteForLocal();