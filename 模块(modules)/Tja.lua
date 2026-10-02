local module = {}

local getArgs = require('Module:Arguments').getArgs

local kanas = {
	{'a', 'あ', 'ア'},	--清音
	{'i', 'い', 'イ'},
	{'u', 'う', 'ウ'},
	{'e', 'え', 'エ'},
	{'o', 'お', 'オ'},
	{'ka', 'か', 'カ'},
	{'ki', 'き', 'キ'},
	{'ku', 'く', 'ク'},
	{'ke', 'け', 'ケ'},
	{'ko', 'こ', 'コ'},
	{'sa', 'さ', 'サ'},
	{'shi', 'し', 'シ'},
	{'su', 'す', 'ス'},
	{'se', 'せ', 'セ'},
	{'so', 'そ', 'ソ'},
	{'ta', 'た', 'タ'},
	{'chi', 'ち', 'チ'},
	{'tsu', 'つ', 'ツ'},
	{'te', 'て', 'テ'},
	{'to', 'と', 'ト'},
	{'na', 'な', 'ナ'},
	{'ni', 'に', 'ニ'},
	{'nu', 'ぬ', 'ヌ'},
	{'ne', 'ね', 'ネ'},
	{'no', 'の', 'ノ'},
	{'ha', 'は', 'ハ'},
	{'hi', 'ひ', 'ヒ'},
	{'fu', 'ふ', 'フ'},
	{'he', 'へ', 'ヘ'},
	{'ho', 'ほ', 'ホ'},
	{'ma', 'ま', 'マ'},
	{'mi', 'み', 'ミ'},
	{'mu', 'む', 'ム'},
	{'me', 'め', 'メ'},
	{'mo', 'も', 'モ'},
	{'ya', 'や', 'ヤ'},
	{'yu', 'ゆ', 'ユ'},
	{'yo', 'よ', 'ヨ'},
	{'ra', 'ら', 'ラ'},
	{'ri', 'り', 'リ'},
	{'ru', 'る', 'ル'},
	{'re', 'れ', 'レ'},
	{'ro', 'ろ', 'ロ'},
	{'wa', 'わ', 'ワ'},
	{'wo', 'を', 'ヲ'},
	
	{'n', 'ん', 'ン'},	--拨音
	
	{'ga', 'が', 'ガ'},	--浊音
	{'gi', 'ぎ', 'ギ'},
	{'gu', 'ぐ', 'グ'},
	{'ge', 'げ', 'ゲ'},
	{'go', 'ご', 'ゴ'},
	{'za', 'ざ', 'ザ'},
	{'ji', 'じ', 'ジ'},
	{'zu', 'ず', 'ズ'},
	{'ze', 'ぜ', 'ゼ'},
	{'zo', 'ぞ', 'ゾ'},
	{'da', 'だ', 'ダ'},
	{'ji', 'ぢ', 'ヂ'},
	{'zu', 'づ', 'ヅ'},
	{'de', 'で', 'デ'},
	{'do', 'ど', 'ド'},
	{'ba', 'ば', 'バ'},
	{'bi', 'び', 'ビ'},
	{'bu', 'ぶ', 'ブ'},
	{'be', 'べ', 'ベ'},
	{'bo', 'ぼ', 'ボ'},
	
	{'pa', 'ぱ', 'パ'},	--半浊音
	{'pi', 'ぴ', 'ピ'},
	{'pu', 'ぷ', 'プ'},
	{'pe', 'ぺ', 'ペ'},
	{'po', 'ぽ', 'ポ'},
	
	{'vu', 'ゔ', 'ヴ'},	--外来语
	
	{'wi', 'ゐ', 'ヰ'},	--方言、古语
	{'we', 'ゑ', 'ヱ'},
	{'-', 'ー', '—'}	--长音
	}
	
local youon = {
	{'kya', 'きゃ', 'キャ'},	--拗音
	{'gya', 'ぎゃ', 'ギャ'},
	{'sha', 'しゃ', 'シャ'},
	{'ja', 'じゃ', 'ジャ'},
	{'cha', 'ちゃ', 'チャ'},
	{'ja', 'ぢゃ', 'ヂャ'},
	{'nya', 'にゃ', 'ニャ'},
	{'hya', 'ひゃ', 'ヒャ'},
	{'bya', 'びゃ', 'ビャ'},
	{'pya', 'ぴゃ', 'ピャ'},
	{'mya', 'みゃ', 'ミャ'},
	{'rya', 'りゃ', 'リャ'},
	{'kyu', 'きゅ', 'キュ'},
	{'gyu', 'ぎゅ', 'ギュ'},
	{'shu', 'しゅ', 'シュ'},
	{'ju', 'じゅ', 'ジュ'},
	{'chu', 'ちゅ', 'チュ'},
	{'ju', 'ぢゅ', 'ヂュ'},
	{'nyu', 'にゅ', 'ニュ'},
	{'hyu', 'ひゅ', 'ヒュ'},
	{'byu', 'びゅ', 'ビュ'},
	{'pyu', 'ぴゅ', 'ピュ'},
	{'myu', 'みゅ', 'ミュ'},
	{'ryu', 'りゅ', 'リュ'},
	{'kyo', 'きょ', 'キョ'},
	{'gyo', 'ぎょ', 'ギョ'},
	{'sho', 'しょ', 'ショ'},
	{'jo', 'じょ', 'ジョ'},
	{'cho', 'ちょ', 'チョ'},
	{'jo', 'ぢょ', 'ヂョ'},
	{'nyo', 'にょ', 'ニョ'},
	{'hyo', 'ひょ', 'ヒョ'},
	{'byo', 'びょ', 'ビョ'},
	{'pyo', 'ぴょ', 'ピョ'},
	{'myo', 'みょ', 'ミョ'},
	{'ryo', 'りょ', 'リョ'},
	
	{'yi', 'いぃ', 'イィ'},	--扩展假名，https://en.wikipedia.org/wiki/Hepburn_romanization#Extended_katakana
	{'ye', 'いぇ', 'イェ'},
	{'wa', 'うぁ', 'ウァ'},
	{'wi', 'うぃ', 'ウィ'},
	{'wu', 'うぅ', 'ウゥ'},
	{'we', 'うぇ', 'ウェ'},
	{'wo', 'うぉ', 'ウォ'},
	{'wyu', 'うゅ', 'ウュ'},
	{'va', 'ゔぁ', 'ヴァ'},
	{'vi', 'ゔぃ', 'ヴィ'},
	{'ve', 'ゔぇ', 'ヴェ'},
	{'vo', 'ゔぉ', 'ヴォ'},
	{'vya', 'ゔゃ', 'ヴャ'},
	{'vyu', 'ゔゅ', 'ヴュ'},
	{'vye', 'ゔぃぇ', 'ウィェ'},
	{'vyo', 'ゔょ', 'ヴョ'},
	{'kye', 'きぇ', 'キェ'},
	{'gye', 'ぎぇ', 'ギェ'},
	{'kwa', 'くぁ', 'クァ'},
	{'kwi', 'くぃ', 'クィ'},
	{'kwe', 'くぇ', 'クェ'},
	{'kwo', 'くぉ', 'クォ'},
	{'kwa', 'くゎ', 'クヮ'},
	{'gwa', 'ぐぁ', 'グァ'},
	{'gwi', 'ぐぃ', 'グィ'},
	{'gwe', 'ぐぇ', 'グェ'},
	{'gwo', 'ぐぉ', 'グォ'},
	{'gwa', 'ぐゎ', 'グヮ'},
	{'she', 'しぇ', 'シェ'},
	{'je', 'じぇ', 'ジェ'},
	{'si', 'すぃ', 'スィ'},
	{'zi', 'ずぃ', 'ズィ'},
	{'che', 'ちぇ', 'チェ'},
	{'tsa', 'つぁ', 'ツァ'},
	{'tsi', 'つぃ', 'ツィ'},
	{'tse', 'つぇ', 'ツェ'},
	{'tso', 'つぉ', 'ツォ'},
	{'tsyu', 'つゅ', 'ツュ'},
	{'ti', 'てぃ', 'ティ'},
	{'tu', 'とぅ', 'トゥ'},
	{'tyu', 'てゅ', 'テュ'},
	{'di', 'でぃ', 'ディ'},
	{'du', 'どぅ', 'ドゥ'},
	{'dyu', 'でゅ', 'デュ'},
	{'nye', 'にぇ', 'ニェ'},
	{'hye', 'ひぇ', 'ヒェ'},
	{'bye', 'びぇ', 'ビェ'},
	{'pye', 'ぴぇ', 'ピェ'},
	{'fa', 'ふぁ', 'ファ'},
	{'fi', 'ふぃ', 'フィ'},
	{'fe', 'ふぇ', 'フェ'},
	{'fo', 'ふぉ', 'フォ'},
	{'fya', 'ふゃ', 'フャ'},
	{'fyu', 'ふゅ', 'フュ'},
	{'fye', 'ふぃぇ', 'フィェ'},
	{'fyo', 'ふょ', 'フョ'},
	{'hu', 'ほぅ', 'ホゥ'},
	{'mye', 'みぇ', 'ミェ'},
	{'rye', 'りぇ', 'リェ'},
	{'va', 'わ゙', 'ヷ'},
	{'vi', 'ゐ゙', 'ヸ'},
	{'ve', 'ゑ゙', 'ヹ'},
	{'vo', 'を゙', 'ヺ'},
}

local hebon = {
	{'kyā', 'きゃあ', 'キャア'},
	{'gyā', 'ぎゃあ', 'ギャア'},
	{'shā', 'しゃあ', 'シャア'},
	{'jā', 'じゃあ', 'ジャア'},
	{'chā', 'ちゃあ', 'チャア'},
	{'jā', 'ぢゃあ', 'ヂャア'},
	{'nyā', 'にゃあ', 'ニャア'},
	{'hyā', 'ひゃあ', 'ヒャア'},
	{'byā', 'びゃあ', 'ビャア'},
	{'pyā', 'ぴゃあ', 'ピャア'},
	{'myā', 'みゃあ', 'ミャア'},
	{'ryā', 'りゃあ', 'リャア'},
	{'kyū', 'きゅう', 'キュウ'},
	{'gyū', 'ぎゅう', 'ギュウ'},
	{'shū', 'しゅう', 'シュウ'},
	{'jū', 'じゅう', 'ジュウ'},
	{'chū', 'ちゅう', 'チュウ'},
	{'jū', 'ぢゅう', 'ヂュウ'},
	{'nyū', 'にゅう', 'ニュウ'},
	{'hyū', 'ひゅう', 'ヒュウ'},
	{'byū', 'びゅう', 'ビュウ'},
	{'pyū', 'ぴゅう', 'ピュウ'},
	{'myū', 'みゅう', 'ミュウ'},
	{'ryū', 'りゅう', 'リュウ'},
	{'kyō', 'きょう', 'キョウ'},
	{'gyō', 'ぎょう', 'ギョウ'},
	{'shō', 'しょう', 'ショウ'},
	{'jō', 'じょう', 'ジョウ'},
	{'chō', 'ちょう', 'チョウ'},
	{'jō', 'ぢょう', 'ヂョウ'},
	{'nyō', 'にょう', 'ニョウ'},
	{'hyō', 'ひょう', 'ヒョウ'},
	{'byō', 'びょう', 'ビョウ'},
	{'pyō', 'ぴょう', 'ピョウ'},
	{'myō', 'みょう', 'ミョウ'},
	{'ryō', 'りょう', 'リョウ'}
}

local sutegana = {
	{'la', 'ぁ', 'ァ'},	--小写假名
	{'li', 'ぃ', 'ィ'},
	{'lu', 'ぅ', 'ゥ'},
	{'le', 'ぇ', 'ェ'},
	{'lo', 'ぉ', 'ォ'},
	
	{'ltsu', 'っ', 'ッ'},
	
	{'lka', 'ゕ', 'ヵ'},
	{'lke', 'ゖ', 'ヶ'},
	
	{'lya', 'ゃ', 'ャ'},
	{'lyu', 'ゅ', 'ュ'},
	{'lyo', 'ょ', 'ョ'},
	
	{'lwa', 'ゎ', 'ヮ'},
	
	{'lku', 'ㇰ'},	--阿伊努语，朝鲜语和台湾话假名扩展，http://www.geocities.jp/aynuitak/kotoeri4_kanahenkan.htm
	{'lshi', 'ㇱ'},
	{'lsu', 'ㇲ'},
	{'lto', 'ㇳ'},
	{'ln', 'ㇴ'},
	{'lha', 'ㇵ'},
	{'lhi', 'ㇶ'},
	{'lfu', 'ㇷ'},
	{'lhe', 'ㇸ'},
	{'lho', 'ㇹ'},
	{'lp', 'ㇷ゚'},
	{'lm', 'ㇺ'},
	{'lra', 'ㇻ'},
	{'lri', 'ㇼ'},
	{'lru', 'ㇽ'},
	{'lre', 'ㇾ'},
	{'lro', 'ㇿ'}
}

local inputSub = {	--输入辅助，该table中的替换规则在inputKana中具有最高优先级
	{'yi', 'い', 'イ'},
	{'wu', 'う', 'ウ'},
	{'wi', 'ゐ', 'ヰ'},
	{'we', 'ゑ', 'ヱ'},
	{'kwa', 'くぁ', 'クァ'},
	{'gwa', 'ぐぁ', 'グァ'},
	{'si', 'し', 'シ'},
	{'ji', 'じ', 'ジ'},
	{'zi', 'じ', 'ジ'},
	{'zu', 'ず', 'ズ'},
	{'ja', 'じゃ', 'ジャ'},
	{'ju', 'じゅ', 'ジュ'},
	{'jo', 'じょ', 'ジョ'},
	{'ti', 'ち', 'チ'},
	{'tu', 'つ', 'ツ'},
	{'tyu', 'ちゅ', 'チュ'},
	{'di', 'ぢ', 'ヂ'},
	{'du', 'づ', 'ヅ'},
	{'dyu', 'ぢゅ', 'ヂュ'},
	{'hu', 'ふ', 'フ'},
	{'va', 'ゔぁ', 'ヴァ'},
	{'vi', 'ゔぃ', 'ヴィ'},
	{'ve', 'ゔぇ', 'ヴェ'},
	{'vo', 'ゔぉ', 'ヴォ'},
	{'vye', 'ゔぇ', 'ヴェ'},
	{'wa', 'わ', 'ワ'},
	{'wo', 'を', 'ヲ'},
	
	{'wha', 'うぁ', 'ウァ'},	--罗马字输入表扩展，https://support.microsoft.com/ja-jp/help/883232
	{'whi', 'うぃ', 'ウィ'},
	{'whu', 'う', 'ウ'},
	{'whe', 'うぇ', 'ウェ'},
	{'who', 'うぉ', 'ウォ'},
	
	{'ca', 'か', 'カ'},
	{'cu', 'く', 'ク'},
	{'qu', 'く', 'ク'},
	{'co', 'こ', 'コ'},
	{'kyi', 'きぃ', 'キィ'},
	{'qya', 'くゃ', 'クャ'},
	{'qyu', 'くゅ', 'クュ'},
	{'qyo', 'くょ', 'クョ'},
	{'qwa', 'くぁ', 'クァ'},
	{'qa', 'くぁ', 'クァ'},
	{'qwi', 'くぃ', 'クィ'},
	{'qyi', 'くぃ', 'クィ'},
	{'qi', 'くぃ', 'クィ'},
	{'qwu', 'くぅ', 'クゥ'},
	{'kwu', 'くぅ', 'クゥ'},
	{'qwe', 'くぇ', 'クェ'},
	{'qye', 'くぇ', 'クェ'},
	{'qe', 'くぇ', 'クェ'},
	{'qwo', 'くぉ', 'クォ'},
	{'qo', 'くぉ', 'クォ'},
	{'gyi', 'ぎぃ', 'ギィ'},
	{'gwu', 'ぐぅ', 'グゥ'},
	
	{'ci', 'し', 'シ'},
	{'ce', 'せ', 'セ'},
	{'sya', 'しゃ', 'シャ'},
	{'syi', 'しぃ', 'シィ'},
	{'syu', 'しゅ', 'シュ'},
	{'sye', 'しぇ', 'シェ'},
	{'syo', 'しょ', 'ショ'},
	{'swa', 'すぁ', 'スァ'},
	{'swi', 'すぃ', 'スィ'},
	{'swu', 'すぅ', 'スゥ'},
	{'swe', 'すぇ', 'スェ'},
	{'swo', 'すぉ', 'スォ'},
	{'zya', 'じゃ', 'ジャ'},
	{'jya', 'じゃ', 'ジャ'},
	{'zyi', 'じぃ', 'ジィ'},
	{'jyi', 'じぃ', 'ジィ'},
	{'zyu', 'じゅ', 'ジュ'},
	{'jyu', 'じゅ', 'ジュ'},
	{'zye', 'じぇ', 'ジェ'},
	{'jye', 'じぇ', 'ジェ'},
	{'zyo', 'じょ', 'ジョ'},
	{'jyo', 'じょ', 'ジョ'},
	
	{'tya', 'ちゃ', 'チャ'},
	{'cya', 'ちゃ', 'チャ'},
	{'tyi', 'ちぃ', 'チィ'},
	{'cyi', 'ちぃ', 'チィ'},
	{'cyu', 'ちゅ', 'チュ'},
	{'tye', 'ちぇ', 'チェ'},
	{'cye', 'ちぇ', 'チェ'},
	{'tyo', 'ちょ', 'チョ'},
	{'cyo', 'ちょ', 'チョ'},
	{'tha', 'てゃ', 'テャ'},
	{'thi', 'てぃ', 'ティ'},
	{'thu', 'てゅ', 'テュ'},
	{'the', 'てぇ', 'テェ'},
	{'tho', 'てょ', 'テョ'},
	{'twa', 'とぁ', 'トァ'},
	{'twi', 'とぃ', 'トィ'},
	{'twu', 'とぅ', 'トゥ'},
	{'twe', 'とぇ', 'トェ'},
	{'two', 'とぉ', 'トォ'},
	{'dya', 'ぢゃ', 'ヂャ'},
	{'dyi', 'ぢぃ', 'ヂィ'},
	{'dye', 'ぢぇ', 'ヂェ'},
	{'dyo', 'ぢょ', 'ヂョ'},
	{'dha', 'でゃ', 'デャ'},
	{'dhi', 'でぃ', 'ディ'},
	{'dhu', 'でゅ', 'デュ'},
	{'dhe', 'でぇ', 'デェ'},
	{'dho', 'でょ', 'デョ'},
	{'dwa', 'どぁ', 'ドァ'},
	{'dwi', 'どぃ', 'ドィ'},
	{'dwu', 'どぅ', 'ドゥ'},
	{'dwe', 'どぇ', 'ドェ'},
	{'dwo', 'どぉ', 'ドォ'},
	
	{'nyi', 'にぃ', 'ニィ'},
	
	{'hyi', 'ひぃ', 'ヒィ'},
	{'fwa', 'ふぁ', 'ファ'},
	{'fwi', 'ふぃ', 'フィ'},
	{'fyi', 'ふぃ', 'フィ'},
	{'fwu', 'ふぅ', 'フゥ'},
	{'fwe', 'ふぇ', 'フェ'},
	{'fye', 'ふぇ', 'フェ'},
	{'fwo', 'ふぉ', 'フォ'},
	{'byi', 'びぃ', 'ビィ'},
	{'vyi', 'ゔぃ', 'ヴィ'},
	{'pyi', 'ぴぃ', 'ピィ'},
	
	{'myi', 'みぃ', 'ミィ'},
	
	{'ryi', 'りぃ', 'リィ'},
	
	{'nn', 'ん', 'ン'},
	{'xn', 'ん', 'ン'},
	
	{'xa', 'ぁ', 'ァ'},	--小写假名输入扩展
	{'xi', 'ぃ', 'ィ'},
	{'lyi', 'ぃ', 'ィ'},
	{'xyi', 'ぃ', 'ィ'},
	{'xu', 'ぅ', 'ゥ'},
	{'xe', 'ぇ', 'ェ'},
	{'lye', 'ぇ', 'ェ'},
	{'xye', 'ぇ', 'ェ'},
	{'xo', 'ぉ', 'ォ'},
	
	{'xka', 'ゕ', 'ヵ'},
	{'xke', 'ゖ', 'ヶ'},
	
	{'ltu', 'っ', 'ッ'},
	{'xtu', 'っ', 'ッ'},
	{'xtsu', 'っ', 'ッ'},
	
	{'xya', 'ゃ', 'ャ'},
	{'xyu', 'ゅ', 'ュ'},
	{'xyo', 'ょ', 'ョ'},
	
	{'xwa', 'ゎ', 'ヮ'},
	
	{'xku', 'ㇰ'},	--阿伊努语，朝鲜语和台湾话假名输入扩展
	{'xshi', 'ㇱ'},
	{'lsi', 'ㇱ'},
	{'xsi', 'ㇱ'},
	{'xsu', 'ㇲ'},
	{'xto', 'ㇳ'},
	{'xn', 'ㇴ'},
	{'lnu', 'ㇴ'},
	{'xnu', 'ㇴ'},
	{'xha', 'ㇵ'},
	{'xhi', 'ㇶ'},
	{'xfu', 'ㇷ'},
	{'lhu', 'ㇷ'},
	{'xhu', 'ㇷ'},
	{'xhe', 'ㇸ'},
	{'xho', 'ㇹ'},
	{'xp', 'ㇷ゚'},
	{'lpu', 'ㇷ゚'},
	{'xpu', 'ㇷ゚'},
	{'xm', 'ㇺ'},
	{'lmu', 'ㇺ'},
	{'xmu', 'ㇺ'},
	{'xra', 'ㇻ'},
	{'xri', 'ㇼ'},
	{'xru', 'ㇽ'},
	{'xre', 'ㇾ'},
	{'xro', 'ㇿ'}
}

function _main(args)
	local roma = args[1]
	
	local space = ''
	if args['s'] == '1' then
		space = ' '	
	end
	
	roma = string.gsub(roma, "'", '/_delimit_/')
	
	for i=1, mw.ustring.len(roma) do
	local kana = mw.ustring.sub(roma, i, i)
	
	if mw.ustring.find(kana, '[っッんン]') then
		local next = mw.ustring.sub(roma, i + 1, i + 1)
		for k, v in ipairs(kanas) do
			for key, val in ipairs(v) do
				if kana == 'っ' or kana == 'ッ' then
					if next == val then
						local nextRomaFirst = string.sub(v[1], 1, 1)
						if string.find(nextRomaFirst, '[^an]') then
				  		roma = mw.ustring.gsub(roma, '[っッ]', nextRomaFirst, 1)
						end
					end
				end
			end
		end
	end
	end
	
	for i=1, mw.ustring.len(roma) do
		local kana = mw.ustring.sub(roma, i, i)
	local next = mw.ustring.sub(roma, i + 1, i + 1)
		if kana == 'ん' or kana == 'ン' then
			if mw.ustring.find(next, '[あいうえおアイウエオやゆよヤユヨ]') then
				local left = mw.ustring.sub(roma, 1, i - 1)
				local right = mw.ustring.sub(roma, i, -1)
				right = mw.ustring.gsub(right, '[んン]', "n'", 1)
				roma = left..right
			end
		end
	end
	
	function iter(str, table)
	for k, v in ipairs(table) do
		for ind, val in ipairs(v) do
			repeat 
				if ind == 1 then break end 
				str = mw.ustring.gsub(str, val, v[1]..space)
			until true
		end
	end
	return str
	end
	
	if args['s'] ~= '1' then
		roma = iter(roma, hebon)
	end
	roma = iter(roma, youon)
	roma = iter(roma, kanas)
	
	if args['s'] == '1' then
		roma = string.reverse(roma):gsub(space, '', 1):reverse()
	end

	roma = string.gsub(roma, 'cchi', 'tchi'):gsub('ccha', 'tcha'):gsub('cchu', 'tchu'):gsub('ccho', 'tcho')
	roma = mw.ustring.gsub(roma, '[っッ]', '')
	roma = mw.ustring.gsub(roma, 'a%-', 'ā'):gsub('i%-', 'ī'):gsub('u%-', 'ū'):gsub('e%-', 'ē'):gsub('o%-', 'ō')
	:gsub('aa', 'ā'):gsub('uu', 'ū'):gsub('ee', 'ē'):gsub('ou', 'ō'):gsub('oo', 'ō')
	roma = string.gsub(roma, '/_delimit_/', '')
	
	return roma
end

function _inputKana(args)
	for i, v in ipairs(args) do
		args[i] = mw.text.split(v, ' ')
	end
	
	function iter(frag, index, roma, tbe)
		for i, v in ipairs(tbe) do
			for i, value in ipairs(v) do
				if roma == value[1] then
					if frag[1] ~= 'k' then
						frag[index] = value[2]
					else
						frag[index] = value[3] or value[2]
					end
					return
				end
			end
		end
	end
	
	for i, frag in ipairs(args) do
		for index, roma in ipairs(frag) do
			iter(frag, index, roma, {
				inputSub, youon, kanas, sutegana
			})
		end
	end
	
	local str = ''
	for i, v in ipairs(args) do
		for i, v in ipairs(v) do
			str = str..v
		end
	end
	str = mw.ustring.gsub(str, '—', 'ー'):gsub('k', '')
	return str
end

function module.main(frame)
	local args = getArgs(frame, {wrappers='Template:Tja'})
	return _main(args)
end

function module.inputKana(frame)
	local args = getArgs(frame)
	return _inputKana(args)	
end

return module