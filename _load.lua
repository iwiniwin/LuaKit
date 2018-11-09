-- 每个文件可通过require本文件获取公共环境
require("core.object")
require("lib.string")

time = require("lib.time")

dump = require("utils.dump")


dumpToFile = require("utils.dumpToFile").dumpToFile

--[[
    什么叫组合 Composition
    在类中增加一个私有域，引用另一个已有的类的实例，通过调用实例的方法从而获得新的功能
]]