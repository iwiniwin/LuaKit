--[[--
ModuleConfig
@module ModuleConfig
@author iwiniwin

Date   2019-11-15 19:20:39
Last Modified by   iwiniwin
Last Modified time 2020-01-16 13:38:52
]]
local ModuleConfig = {}

ModuleConfig.Module1 = {
    file = "mvc.module1.Test1View",
    initOrder = 2,
}

ModuleConfig.Module2 = {
    file = "mvc.module2.Test2View",
    initOrder = 1,
}

return ModuleConfig