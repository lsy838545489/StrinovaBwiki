local getArgs = require("Module:Arguments").getArgs
local f = string.format
local p = {}

function p.main(frame)
	local mwArgs = getArgs(frame, {
		removeBlanks = false,
	})
	local args = {}
	for k, v in pairs(mwArgs) do
		args[k] = v
	end

	local originalLang = args.llang or "ja"
	local translatedLang = args.rlang or "zh"

	local lstyle = args.lstyle or "color: rgb(255, 255, 224);"
	local rstyle = args.rstyle or "color: rgb(255, 192, 203);"

	if (#args % 2 ~= 0) then
		error(f("匿名参数数量（当前：%d）不是偶数，必须是原文+翻译成对出现。", #args))
	end

	local lyricTable = { 
		'<div class="row">\n', 
		'<div class="col-sm-12">\n',
		'本段落中所使用的歌词，其著作权属于原著作权人，仅以介绍为目的引用。',
		'</div>\n',
	}
	local function addLine(text)
		lyricTable[#lyricTable+1] = text
	end

	for i = 1, #args, 2 do
		local originalText = args[i]
		local translatedText = args[i + 1]

		addLine(f('<div class="col-sm-6 original-lang"><span style="%s" lang="%s">%s</span></div>\n', lstyle, originalLang, originalText or ""))
		addLine(f('<div class="col-sm-6 translated-lang"><span style="%s" lang="%s">%s</span></div>\n', rstyle, translatedLang, translatedText or ""))
	end

	addLine('</div>')
	return table.concat(lyricTable, "\n")
end

return p