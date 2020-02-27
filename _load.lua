--[[--
每个文件可通过require本文件获取公共环境
@module _load
@author iwiniwin

Date   2019-11-15 19:20:39
Last Modified by   iwiniwin
Last Modified time 2020-01-16 13:57:21
]]
require("core.object")
require("lib.string")
local func_lib = require("lib.function")

time = require("lib.time")

dump = require("utils.dump")


dump_to_file = require("utils.dump_to_file").dump_to_file

handler = func_lib.handler

--[[
    什么叫组合 Composition
    在类中增加一个私有域，引用另一个已有的类的实例，通过调用实例的方法从而获得新的功能
]]