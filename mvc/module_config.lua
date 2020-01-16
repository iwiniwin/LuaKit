--[[--
ModuleConfig
@module ModuleConfig
@author iwiniwin

Date   2019-11-15 19:20:39
Last Modified by   iwiniwin
Last Modified time 2020-01-16 13:59:10
]]
local ModuleConfig = {}

ModuleConfig.Module1 = {
    file = "mvc.module1.test1_view",
    initOrder = 2,
}

ModuleConfig.Module2 = {
    file = "mvc.module2.test2_view",
    initOrder = 1,
}

return ModuleConfig