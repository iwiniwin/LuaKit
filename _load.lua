--[[--
控制台测试脚本
@module _load
@author iwiniwin

Date   2019-11-15 19:20:39
Last Modified by   iwiniwin
Last Modified time 2020-01-16 13:57:21
]]
require("init")()

dump("Hello LuaKit")

-- require("test")  -- 运行测试用例

--[[
    什么叫组合 Composition
    在类中增加一个私有域，引用另一个已有的类的实例，通过调用实例的方法从而获得新的功能
]]