--[[--
LuaKit初始化函数，初始化全局变量
@module init
@author iwiniwin

Date   2021-09-04 20:20:39
Last Modified by   iwiniwin
Last Modified time 2021-09-04 20:20:39
]]
local init = function ( requirePrefix )

	if requirePrefix then
		import = function ( modname )
			return require(requirePrefix .. modname)
		end
	else
		import = require
	end

	import("core.object")
	import("lib.string")
	local func_lib = import("lib.function")

	time = import("lib.time")

	dump = import("utils.dump")


	dump_to_file = import("utils.dump_to_file").dump_to_file

	handler = func_lib.handler

end

return init