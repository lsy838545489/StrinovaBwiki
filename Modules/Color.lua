-- 原模块:https://mzh.moegirl.org.cn/模块:Color
-- 该模块主要用于操作颜色。
 
local colorKeywords = {
  aliceblue = { 240, 248, 255 },
  antiquewhite = { 250, 235, 215 },
  aqua = { 0, 255, 255 },
  aquamarine = { 127, 255, 212 },
  azure = { 240, 255, 255 },
  beige = { 245, 245, 220 },
  bisque = { 255, 228, 196 },
  black = { 0, 0, 0 },
  blanchedalmond = { 255, 235, 205 },
  blue = { 0, 0, 255 },
  blueviolet = { 138, 43, 226 },
  brown = { 165, 42, 42 },
  burlywood = { 222, 184, 135 },
  cadetblue = { 95, 158, 160 },
  chartreuse = { 127, 255, 0 },
  chocolate = { 210, 105, 30 },
  coral = { 255, 127, 80 },
  cornflowerblue = { 100, 149, 237 },
  cornsilk = { 255, 248, 220 },
  crimson = { 220, 20, 60 },
  cyan = { 0, 255, 255 },
  darkblue = { 0, 0, 139 },
  darkcyan = { 0, 139, 139 },
  darkgoldenrod = { 184, 134, 11 },
  darkgray = { 169, 169, 169 },
  darkgreen = { 0, 100, 0 },
  darkgrey = { 169, 169, 169 },
  darkkhaki = { 189, 183, 107 },
  darkmagenta = { 139, 0, 139 },
  darkolivegreen = { 85, 107, 47 },
  darkorange = { 255, 140, 0 },
  darkorchid = { 153, 50, 204 },
  darkred = { 139, 0, 0 },
  darksalmon = { 233, 150, 122 },
  darkseagreen = { 143, 188, 143 },
  darkslateblue = { 72, 61, 139 },
  darkslategray = { 47, 79, 79 },
  darkslategrey = { 47, 79, 79 },
  darkturquoise = { 0, 206, 209 },
  darkviolet = { 148, 0, 211 },
  deeppink = { 255, 20, 147 },
  deepskyblue = { 0, 191, 255 },
  dimgray = { 105, 105, 105 },
  dimgrey = { 105, 105, 105 },
  dodgerblue = { 30, 144, 255 },
  firebrick = { 178, 34, 34 },
  floralwhite = { 255, 250, 240 },
  forestgreen = { 34, 139, 34 },
  fuchsia = { 255, 0, 255 },
  gainsboro = { 220, 220, 220 },
  ghostwhite = { 248, 248, 255 },
  gold = { 255, 215, 0 },
  goldenrod = { 218, 165, 32 },
  gray = { 128, 128, 128 },
  green = { 0, 128, 0 },
  greenyellow = { 173, 255, 47 },
  grey = { 128, 128, 128 },
  honeydew = { 240, 255, 240 },
  hotpink = { 255, 105, 180 },
  indianred = { 205, 92, 92 },
  indigo = { 75, 0, 130 },
  ivory = { 255, 255, 240 },
  khaki = { 240, 230, 140 },
  lavender = { 230, 230, 250 },
  lavenderblush = { 255, 240, 245 },
  lawngreen = { 124, 252, 0 },
  lemonchiffon = { 255, 250, 205 },
  lightblue = { 173, 216, 230 },
  lightcoral = { 240, 128, 128 },
  lightcyan = { 224, 255, 255 },
  lightgoldenrodyellow = { 250, 250, 210 },
  lightgray = { 211, 211, 211 },
  lightgreen = { 144, 238, 144 },
  lightgrey = { 211, 211, 211 },
  lightpink = { 255, 182, 193 },
  lightsalmon = { 255, 160, 122 },
  lightseagreen = { 32, 178, 170 },
  lightskyblue = { 135, 206, 250 },
  lightslategray = { 119, 136, 153 },
  lightslategrey = { 119, 136, 153 },
  lightsteelblue = { 176, 196, 222 },
  lightyellow = { 255, 255, 224 },
  lime = { 0, 255, 0 },
  limegreen = { 50, 205, 50 },
  linen = { 250, 240, 230 },
  magenta = { 255, 0, 255 },
  maroon = { 128, 0, 0 },
  mediumaquamarine = { 102, 205, 170 },
  mediumblue = { 0, 0, 205 },
  mediumorchid = { 186, 85, 211 },
  mediumpurple = { 147, 112, 219 },
  mediumseagreen = { 60, 179, 113 },
  mediumslateblue = { 123, 104, 238 },
  mediumspringgreen = { 0, 250, 154 },
  mediumturquoise = { 72, 209, 204 },
  mediumvioletred = { 199, 21, 133 },
  midnightblue = { 25, 25, 112 },
  mintcream = { 245, 255, 250 },
  mistyrose = { 255, 228, 225 },
  moccasin = { 255, 228, 181 },
  navajowhite = { 255, 222, 173 },
  navy = { 0, 0, 128 },
  oldlace = { 253, 245, 230 },
  olive = { 128, 128, 0 },
  olivedrab = { 107, 142, 35 },
  orange = { 255, 165, 0 },
  orangered = { 255, 69, 0 },
  orchid = { 218, 112, 214 },
  palegoldenrod = { 238, 232, 170 },
  palegreen = { 152, 251, 152 },
  paleturquoise = { 175, 238, 238 },
  palevioletred = { 219, 112, 147 },
  papayawhip = { 255, 239, 213 },
  peachpuff = { 255, 218, 185 },
  peru = { 205, 133, 63 },
  pink = { 255, 192, 203 },
  plum = { 221, 160, 221 },
  powderblue = { 176, 224, 230 },
  purple = { 128, 0, 128 },
  red = { 255, 0, 0 },
  rosybrown = { 188, 143, 143 },
  royalblue = { 65, 105, 225 },
  saddlebrown = { 139, 69, 19 },
  salmon = { 250, 128, 114 },
  sandybrown = { 244, 164, 96 },
  seagreen = { 46, 139, 87 },
  seashell = { 255, 245, 238 },
  sienna = { 160, 82, 45 },
  silver = { 192, 192, 192 },
  skyblue = { 135, 206, 235 },
  slateblue = { 106, 90, 205 },
  slategray = { 112, 128, 144 },
  slategrey = { 112, 128, 144 },
  snow = { 255, 250, 250 },
  springgreen = { 0, 255, 127 },
  steelblue = { 70, 130, 180 },
  tan = { 210, 180, 140 },
  teal = { 0, 128, 128 },
  thistle = { 216, 191, 216 },
  tomato = { 255, 99, 71 },
  turquoise = { 64, 224, 208 },
  violet = { 238, 130, 238 },
  wheat = { 245, 222, 179 },
  white = { 255, 255, 255 },
  whitesmoke = { 245, 245, 245 },
  yellow = { 255, 255, 0 },
  yellowgreen = { 154, 205, 50 },
}
 
local rgbRegex = '^rgb%(%s-(%d-),%s-(%d-)%s-,%s-(%d-)%s-%)$'
local rgbaRegex = '^rgba%(%s-(%d-),%s-(%d-)%s-,%s-(%d-)%s-,%s-([%d%.]+)%s-%)$'
local hslRegex = '^hsl%(%s-(%d-),%s-(%d-)%%%s-,%s-(%d-)%%%s-%)$'
local hslaRegex = '^hsla%(%s-(%d-),%s-(%d-)%%%s-,%s-(%d-)%%%s-,%s-([%d%.]+)%s-%)$'
local hexRegex = '^#(%x%x)(%x%x)(%x%x)$'
local hexShorthandRegex = '^#(%x)(%x)(%x)$'
 
--[[
  Color实例结构
  interface ColorInstance {
	__index = Color
    value: [number, number, number]
    format: 'rgb' | 'hsl'
    opacity: number
  }
]]
 
local Color = {}
local colorMetaTable = { __index = Color }
 
--[[
  @param {number} min
  @param {number} max
  
  @return {number}
]]
local function _random(min, max)
  return tonumber(mw.getCurrentFrame():expandTemplate{ title = 'random', args = { min, max } })
end
 
--[[
  @desc 操作颜色加深减淡
 
  @param {[number, number, number]} rgb
  @param {'+' | '-'} operator - 加深，减淡
  @param {number} ratio 范围：0 ~ 100
 
  @return {[number, number, number]}
]]
local function _computeRgb(rgb, operator, ratio)
  local ranges = {}
  local cloneRgb = { rgb[1], rgb[2], rgb[3] }
  for i, v in ipairs(rgb) do
    ranges[i] = {
      ['-'] = (255 - v) / 100,
      ['+'] = -v / 100
    }
  end
 
  for i, v in ipairs(cloneRgb) do
    cloneRgb[i] = v + ranges[i][operator] * ratio
    if cloneRgb[i] < 0 then cloneRgb[i] = 0 end
    if cloneRgb[i] > 255 then cloneRgb[i] = 255 end
  end
  return cloneRgb
end
 
--[[
  @desc 判断一个字符串或table是否为合法的color值
  @param {(string | [number, number, number])} rawValue - 接受一个字符串或数组table，有效的格式有：css颜色关键字，hex颜色，hex简写颜色，rgb函数，rgba函数，hsl函数，hsla函数
 
  @return {boolean}
]]
function Color.isColorStr(rawValue)
  if type(rawValue) == 'string' then
    if
      rawValue:match(rgbRegex) or
      rawValue:match(rgbaRegex) or
      rawValue:match(hslRegex) or
      rawValue:match(hslaRegex) or
      colorKeywords[rawValue]
    then return true end
    rawValue = mw.text.unstripNoWiki(rawValue)
      :gsub('^&#35;', '#')  -- 为了避免解析器自动换行，一些返回颜色值的模板常用'<nowiki>#</nowiki>'或'&#35;'代替'#'
      :gsub('^＃', '#')  -- Bhsd加的全角字符兼容，不知道为啥
    if
      rawValue:match(hexRegex) or
      rawValue:match(hexShorthandRegex)
    then return true end
  elseif type(rawValue) == 'table' then
    if #rawValue ~= 3 and #rawValue ~= 4 then return false end
    for _, v in ipairs(rawValue) do
      if type(v) ~= 'number' then return false end
    end
    return true
  end
 
  return false
end
 
--[[
  @desc 创建一个Color实例
  @param {(string | [number, number, number])} rawValue - 接受一个字符串或数组table，有效的格式有：css颜色关键字，hex颜色，hex简写颜色，rgb函数，rgba函数，hsl函数，hsla函数
 
  @return {(Color | nil)} - 如果rawValue无效，则返回nil
]]
function Color.create(rawValue)
  if not Color.isColorStr(rawValue) then return nil end
  if type(rawValue) == 'string' then
    rawValue =     mw.text.unstripNoWiki(rawValue)
      :gsub('^&#35;', '#')  -- 为了避免解析器自动换行，一些返回颜色值的模板常用'<nowiki>#</nowiki>'或'&#35;'代替'#'
      :gsub('^＃', '#')  -- Bhsd加的全角字符兼容，不知道为啥
  end
 
  local color = setmetatable({}, colorMetaTable)
 
  local r_h, g_s, b_l, opacity -- rgb or hsl
  if type(rawValue) == 'string' then
		if rawValue:match(rgbRegex) then
			color.format = 'rgb'
      r_h, g_s, b_l = rawValue:match(rgbRegex)
 
      r_h = tonumber(r_h)
      g_s = tonumber(g_s)
      b_l = tonumber(b_l)
		elseif rawValue:match(rgbaRegex) then
			color.format = 'rgb'
      r_h, g_s, b_l, opacity = rawValue:match(rgbaRegex)
 
      r_h = tonumber(r_h)
      g_s = tonumber(g_s)
      b_l = tonumber(b_l)
			opacity = tonumber(opacity)
		elseif rawValue:match(hslRegex) then
			color.format = 'hsl'
			r_h, g_s, b_l = rawValue:match(hslRegex)
 
      r_h = tonumber(r_h)
      g_s = tonumber(g_s)
      b_l = tonumber(b_l)
		elseif rawValue:match(hslaRegex) then
			color.format = 'hsl'
      r_h, g_s, b_l, opacity = rawValue:match(hslaRegex)
 
      r_h = tonumber(r_h)
      g_s = tonumber(g_s)
      b_l = tonumber(b_l)
			opacity = tonumber(opacity)
		elseif rawValue:match(hexRegex) then
			color.format = 'rgb'
      r_h, g_s, b_l = rawValue:match(hexRegex)
      r_h = tonumber(r_h, 16)
      g_s = tonumber(g_s, 16)
			b_l = tonumber(b_l, 16)
		elseif rawValue:match(hexShorthandRegex) then
			color.format = 'rgb'
      r_h, g_s, b_l = rawValue:match(hexShorthandRegex)
      r_h = tonumber(r_h, 16) * 17
      g_s = tonumber(g_s, 16) * 17
			b_l = tonumber(b_l, 16) * 17
		else
			color.format = 'rgb'
      local colorkeywordRgb = colorKeywords[rawValue]
      r_h = colorkeywordRgb[1]
      g_s = colorkeywordRgb[2]
      b_l = colorkeywordRgb[3]
    end
	elseif type(rawValue) == 'table' then
		color.format = 'rgb'
    r_h = rawValue[1]
    g_s = rawValue[2]
    b_l = rawValue[3]
    opacity = rawValue[4]
  end
 
  color.value = { r_h, g_s, b_l }
  color.opacity = opacity or 1
  return color
end
 
--[[
  @desc 克隆一个Color对象
 
  @param {Color} this
 
  @return {Color} - 一个新的Color对象
]]
function Color.clone(this)
  local rgb = this:rgb().value
  return Color.create(rgb):setOpacity(this.opacity)
end
 
--[[
  @desc rgb转hsl
 
  @param {number} r
  @param {number} g
  @param {number} b
 
  @return [number, number, number] - 返回的所有值均为整数
]]
function Color.rgb2hsl(r, g, b)
  r = r / 255
  g = g / 255
  b = b / 255
 
  local max = math.max(r, g, b)
  local min = math.min(r, g, b)
  local diff = max - min
 
  local h, s
  local l = (max + min) / 2
 
  if max == min then
    h = 0
    s = 0
  elseif max == r and g >= b then
    h = 60 * ((g - b) / diff)
  elseif max == r and g < b then
    h = 60 * ((g - b) / diff) + 360
  elseif max == g then
    h = 60 * ((b - r) / diff) + 120
  elseif max == b then
    h = 60 * ((r - g) / diff) + 240
  end
 
  if l == 0 or max == min then
    s = 0
  elseif 0 < 1 and l <= 0.5 then
    s = diff / (2 * l)
  elseif l > 0.5 then
    s = diff / (2 - 2 * l)
  end
 
  return {
    math.floor(h + 0.5),
    math.floor(s * 100 + 0.5),
    math.floor(l * 100 + 0.5)
  }
end
 
--[[
  @desc hsl转rgb
 
  @param {number} h
  @param {number} s - css中使用百分比，但该函数需要传整数 50% => 50
  @param {number} l - css中使用百分比，但该函数需要传整数 50% => 50
 
  @return [number, number, number]
]]
function Color.hsl2rgb(h, s, l)
  h = h % 360
  s = s / 100
  l = l / 100
 
  local c = (1 - math.abs(2 * l - 1)) * s
  local x = c * (1 - math.abs(((h / 60) % 2) - 1))
  local m = l - c / 2
  local vRGB = {}
 
  if h >=0 and h < 60 then
    vRGB = {c, x, 0}
  elseif h >= 60 and h < 120 then
    vRGB = {x, c, 0}
  elseif h >= 120 and h < 180 then
    vRGB = {0, c, x}
  elseif h >= 180 and h < 240 then
    vRGB = {0, x, c}
  elseif h >= 240 and h < 300 then
    vRGB = {x, 0, c}
  elseif h >= 300 and h < 360 then
    vRGB = {c, 0, x}
  end
 
  local r = 255 * (vRGB[1] + m)
  local g = 255 * (vRGB[2] + m)
  local b = 255 * (vRGB[3] + m)
 
  return {
    math.floor(r + 0.5),
    math.floor(g + 0.5),
    math.floor(b + 0.5)
  }
end
 
--[[
  @desc 将color对象的数据转为rgb格式
 
  @param {Color} this
  @return {Color} - this
]]
function Color.rgb(this)
  if this.format == 'rgb' then return this end
  if this.format == 'hsl' then
    this.value = Color.hsl2rgb(this.value[1], this.value[2], this.value[3])
    this.format = 'rgb'
  end
 
  return this
end
 
--[[
  @desc 将color对象的数据转为hsl格式
 
  @param {Color} this
  @return {Color} - this
]]
function Color.hsl(this)
  if this.format == 'hsl' then return this end
  if this.format == 'rgb' then
    this.value = Color.rgb2hsl(this.value[1], this.value[2], this.value[3])
    this.format = 'hsl'
  end
 
  return this
end
 
--[[
  @desc 加深一个颜色(明度-)
 
  @param {Color} this
  @param {number} ratio - 范围：0 ~ 100
 
  @return {Color} - this
]]
function Color.darken(this, ratio)
  local rgb = this:rgb().value
  this.value = _computeRgb(rgb, '+', ratio)
 
  return this
end
 
--[[
  @desc 减淡一个颜色(明度+)
 
  @param {Color} this
  @param {number} ratio - 范围：0 ~ 100
 
  @return {Color} - this
]]
function Color.lighten(this, ratio)
  local rgb = this:rgb().value
  this.value = _computeRgb(rgb, '-', ratio)
 
  return this
end
 
--[[
  @desc 提高一个颜色的饱和度
 
  @param {Color} this
  @param {number} ratio - 范围：0 ~ 100
 
  @return {Color} - this
]]
function Color.saturate(this, ratio)
  local hsl = this:hsl().value
  this.value[2] = hsl[2] + (100 - hsl[2]) * (ratio / 100)
  if this.value[2] > 100 then this.value[2] = 100 end
 
  return this
end
 
--[[
  @desc 降低一个颜色的饱和度
 
  @param {Color} this
  @param {number} ratio - 范围：0 ~ 100
 
  @return {Color} - this
]]
function Color.desaturate(this, ratio)
  local hsl = this:hsl().value
  this.value[2] = hsl[2] - hsl[2] * (ratio / 100)
  if this.value[2] < 0 then this.value[2] = 0 end
 
  return this
end
 
--[[
  @desc 混合两个颜色
 
  @param {Color} this 颜色1
  @param {Color} color 颜色2
  @param {number} weight 颜色1比重 范围：0 ~ 100，默认值为50
 
  @return {Color} this
]]
function Color.mix(this, color, weight)
  local color1 = this:rgb()
  local color2 = color:rgb()
  local p = weight == nil and 50 or weight
  p = p / 100
 
  local w = 2 * p - 1
  local a = color1.opacity - color2.opacity
 
  local w1 = (((w * a == -1) and w or (w + a) / (1 + w * a)) + 1) / 2.0
  local w2 = 1 - w1
 
  this.value = {
    w1 * color1.value[1] + w2 * color2.value[1],
    w1 * color1.value[2] + w2 * color2.value[2],
    w1 * color1.value[3] + w2 * color2.value[3]
  }
 
  this:setOpacity(color1.opacity * p + color2.opacity * (1 - p))
 
  return this
end
 
--[[
  @desc 设置一个值的不透明度
 
  @param {Color} this
  @param {number} value - 范围：0 ~ 1
 
  @return {Color} - this
]]
function Color.setOpacity(this, value)
  this.opacity = tonumber(value)
  return this
end
 
--[[
  @desc Gamma校正
 
  @param {number} r_g_b
  @return {number}
]]
local function adjustGamma(r_g_b)
  if r_g_b <= 0.04045 then return r_g_b / 12.92
  else return ((r_g_b + 0.055) / 1.055) ^ 2.4 end
end
 
--[[
  @desc 获得颜色的相对亮度
 
  @param {Color} this
  @return {number}
]]
function Color.getRelativeLuminance(this)
  local rgb = this:rgb().value
  return 0.2126 * adjustGamma(rgb[1] / 255) +
         0.7152 * adjustGamma(rgb[2] / 255) +
         0.0722 * adjustGamma(rgb[3] / 255)
end
 
--[[
  @desc 获得两颜色的对比度比例
 
  @param {Color} this
  @param {Color} color
  @return {number}
]]
function Color.getContrastRatio(this, color)
  local ratio = (this:getRelativeLuminance() + 0.05) / (color:getRelativeLuminance() + 0.05)
  if ratio < 1 then return 1 / ratio
  else return ratio end
end
 
--[[
  @desc 检测一个颜色是否为亮色
 
  @param {Color} this
  @return {boolean}
]]
function Color.isLight(this)
  return this:getRelativeLuminance() > (0.05 * 1.05) ^ 0.5 - 0.05
end
 
--[[
  @desc 检测一个颜色是否为暗色
 
  @param {Color} this
  @return {boolean}
]]
function Color.isDark(this)
  return this:isLight() == false
end
 
--[[
  @desc 根据范围随机产生一个颜色
 
  @param {number} [min = 0] - 范围：0 ~ 255
  @param {number} [max = 255] - 范围：0 ~ 255
 
  @return {Color}
]]
function Color.random(min, max)
  min = min or 0
  max = max or 255
 
  local rgb = {
    _random(min, max),
    _random(min, max),
    _random(min, max)
  }
 
  return Color.create(rgb)
end
 
--[[
  @desc 反转一个颜色
 
  @param {Color} this
 
  @return {Color} - this
]]
function Color.reverse(this)
  local rgb = this:rgb().value
  for i, v in ipairs(rgb) do
    rgb[i] = math.abs(v - 255)
  end
 
  return this
end
 
--[[
  @desc 将一个Color实例转化为有效的css颜色值字符串
 
  @param {Color} this
  @param {('auto' | 'hex' | 'hex-opacity')} [format = 'auto'] - 格式，
    为auto时，根据Color对象本身的format进行转换，使用对应的css函数，并保留透明度。在调用前应该先执行rgb()或hsl()，以明确输出格式。
    为hex时，返回hex颜色。无视透明度。
    为hex-opacity时，返回hex颜色。若不透明度不为1，则假定背景为白色将透明度和颜色进行计算。
]]
function Color.toString(this, format)
  local function toHex(num)
    local int, float = math.modf(num)
    if float > 0.4 then int = int + 1 end
    local zero = ''
    if int < 16 then zero = '0' end
    return zero..string.format('%X', int)
  end
 
  format = format or 'auto'
  if format == 'auto' then
    if this.format == 'rgb' then
      if this.opacity >= 0 and this.opacity < 1 then
        return 'rgba('..table.concat(this.value, ',')..','..this.opacity..')'
      else
        return 'rgb('..table.concat(this.value, ',')..')'
      end
    elseif this.format == 'hsl' then
      local hsl = this.value
      if this.opacity >= 0 and this.opacity < 1 then
        return string.format('hsla(%s, %s%%, %s%%, %s)', hsl[1], hsl[2], hsl[3], this.opacity)
      else
        return string.format('hsl(%s, %s%%, %s%%)', hsl[1], hsl[2], hsl[3])
      end
    end
  elseif format == 'hex' then
    this:rgb()
    return '#'..toHex(this.value[1])..toHex(this.value[2])..toHex(this.value[3])
  elseif format == 'hex-opacity' then
    this:rgb()
    local r = this.value[1]
    local g = this.value[2]
    local b = this.value[3]
 
    r = r + r * (1 - this.opacity)
    g = g + g * (1 - this.opacity)
    b = b + b * (1 - this.opacity)
 
    if r > 255 then r = 255 end
    if g > 255 then g = 255 end
    if b > 255 then b = 255 end
 
    return '#'..toHex(r)..toHex(g)..toHex(b)
  end
end
 
return Color