--[[--ldoc desc
@module Time
@author LensarZhang

Date   2018-04-17 11:53:20
Last Modified by   LensarZhang
Last Modified time 2018-09-14 16:09:04
]]
local Time = {
	
}
os.clock()

---保护环境 人人有责
local env = getfenv();
local protectEnv = function(env)
	local mt  = getmetatable(env);
	local cache = {};
	mt.__newindex = function( t,k,v )
		if cache[k] == nil then
			cache[k] = v;
		else
			if cache[k] ~= v then
				error("不允许复写" .. k)
			end
		end
		rawset(mt.__index, k, v)
	end
end
protectEnv(env);

return Time