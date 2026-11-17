local getArgs = require("Module:Arguments").getArgs
local f = string.format
local p = {}

local function getLangs(args)
	local langCount = 1
	local enabledLangs = {
		{ code = 'zh', tdStyle = 'background-color: rgba(255, 192, 203, 0.5)' },
	}
	for _, lang in ipairs({
		{ code = 'ja', tdStyle = 'background-color: rgba(255, 255, 224, 0.5)' },
		{ code = 'en', tdStyle = 'background-color: rgba(240, 255, 255, 0.5)' },
		{ code = 'ko', tdStyle = '' },
	}) do
		if args[lang.code] then
			langCount = langCount + 1
			enabledLangs[langCount] = lang
		end
	end
	if (#args % (1 + langCount * 2) ~= 0) then
		error(f(
			'匿名参数数量（当前：%d）必须是 (1 + 启用语言数量 (当前：%d) × 2) = %d 的整数倍',
			#args, langCount, (1 + langCount * 2)
		))
	end
	return enabledLangs, langCount
end

function p.main(frame)
	local mwArgs = getArgs(frame, {
		removeBlanks = false,
	})
	-- MW的参数是通过元表（__index, __pairs, __ipairs）获取的，args本身不包括任何内容，这导致`#`无法获取长度。
	-- 此处复制一份，方便后续操作。此外，通过pairs一次性获取所有参数，能够避免频繁与PHP交互。
	local args = {}
	for k, v in pairs(mwArgs) do
		args[k] = v
	end
	local enabledLangs, langCount = getLangs(args)

	local voiceTable = {
		'{| class="klbqtable voice-table"',
	}
	local function addLine(text)
		voiceTable[#voiceTable+1] = text
	end

	for i = 1, #args, 1 + langCount * 2 do
		local name = args[i]
		addLine(f('! rowspan="%d" | %s', langCount, name))

		for langIdx = 1, langCount do
			local lang = enabledLangs[langIdx]
			local audioFileName = args[i + langIdx * 2 - 1]
			local originalText = args[i + langIdx * 2]

			-- 特殊处理"卡拉彼丘"的翻译
			local displayText = originalText
			if name == "卡拉彼丘" then
				if lang.code == 'ja' then
					displayText = 'ストリノヴァ'
				elseif lang.code == 'en' then
					displayText = 'Strinova'
				else
					displayText = '卡拉彼丘'
				end
			end

			local audioPlayer = ''
			if audioFileName ~= '' then
				audioPlayer = '<div style="display: none">[[媒体文件:'..
				audioFileName..
				']]</div><div class="media-audio" data-mini="true" data-file="{{filepath: '..
				audioFileName..
				' | nowiki }}" data-panel="" data-button="" data-progress="" data-dot="" data-bar="" data-preload="none"></div>'
			end

			addLine(f('| style="%s" | %s', lang.tdStyle, audioPlayer))
			addLine(f(
				'| style="%s" %s | %s',
				lang.tdStyle, lang.code ~= 'zh' and 'lang="'..lang.code..'"' or '',
				displayText
			))
			addLine("|-")
		end
	end

	addLine('|}')
	return table.concat(voiceTable, "\n")
end

return p