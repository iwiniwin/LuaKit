require("_load")


-- 测试分模块加载
local function TestLoadModule( ... )
    local moduleList = require("mvc.Loader")

    -- 卸载模块
    for k,v in pairs(moduleList) do
        delete(v)
    end
end
TestLoadModule()

-- https://blog.csdn.net/u012723995/article/details/40455357
-- 模块加载 性能分析 面向对象 组件 事件系统 数据观察追踪 回退系统 MVC
