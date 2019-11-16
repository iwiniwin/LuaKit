--[[--ldoc desc
@author LensarZhang

Date   2019-11-15 19:22:35
Last Modified by   LensarZhang
Last Modified time 2019-11-15 19:24:42
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