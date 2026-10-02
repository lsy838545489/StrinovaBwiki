local module = {}
 
function module.main(frame)
	local arg1 = frame.args[1]
	assert(arg1, '需要参数1！')
	return mw.text.unstripNoWiki(arg1)
end
 
return module