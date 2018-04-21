--[[--ldoc desc
@module String
@author LensarZhang

Date   2018-04-17 19:04:10
Last Modified by   LensarZhang
Last Modified time 2018-04-17 19:13:32
]]
local String = {}

-- 判断str是否以sub开始
String.startsWith = function (str, sub)
	if string.find(str, sub) == 1 then
		return true
	end
	return false
end

-- 判断str是否以sub结尾
String.endsWith = function (str, sub)
	if string.sub(str, #str - #sub + 1, #str) == sub then
		return true
	end
	return false
end


return String