local P = {}

local excludedPages = {
	role = {
		'米雪儿·李', '信', '心夏', '伊薇特', '芙拉薇娅', '忧雾', '蕾欧娜', '千代',
		'明', '拉薇', '梅瑞狄斯', '令', '香奈美', '艾卡', '珐格兰丝', '玛拉', '诺诺',
		'奥黛丽·格罗夫', '玛德蕾娜·利里', '星绘', '白墨', '绯莎', '加拉蒂亚·利里', '汐',
		'爆裂魔怪', '刺镰魔怪', '莉莉丝', '冥荆皇女', '血荆皇女',
	},

	weapon = {
		'警探', '审判官', '空境', '幻霜', '独舞', '绝对执行', '校准仪', '枫鸣',
		'逆焰', '影袭', '隼', '破晓', '谢幕曲', '鸣火', '绽放', '夜镰', '雨晦',
		'卫冕', '彩绘', '北极星', '自由意志', '齿锋', '欺诈师', '潮音',
		'忍锋', '战镰', '大剑', '静风',
	},

	other = {
		'角色时装筛选',
		'武器外观筛选',
		'战斗模式/晶源感染/PC端卡牌筛选',
		'战斗模式/晶源感染/移动端卡牌筛选',
	},
}

local excludedPageSet = {}

for _, pages in pairs(excludedPages) do
	for _, title in ipairs(pages) do
		excludedPageSet[title] = true
	end
end

local seoConfig = {
	title_mode = 'replace',
	locale = 'zh-CN',
	image = '卡拉彼丘手游.jpg',
	keywords = '卡拉彼丘WIKI,卡拉彼丘,卡拉彼丘图鉴,卡拉彼丘攻略,Strinova,ストリノヴァ,纸片人射击,二次元射击',
	description = '卡拉彼丘WIKI（Strinova）是由玩家共同编辑维护的非官方资料站，整理角色、武器、时装、活动、玩法、游戏数据与攻略等内容，为引航者提供完整的卡拉彼丘图鉴与资料。',
}

function P.main(frame)
	local title = mw.title.getCurrentTitle().text

	if excludedPageSet[title] then
		return
	end

	local config = {}
	for k, v in pairs(seoConfig) do
		config[k] = v
	end

	config.title = title .. ' - 卡拉彼丘WIKI'

	mw.ext.seo.set(config)
end

return P