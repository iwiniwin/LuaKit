require("_load")

-- 测试面向对象
local function testOOP( ... )
    local Class1 = class()
    function Class1:ctor( ... )
        dump("Class1:ctor")
    end
    function Class1:dtor( ... )
        dump("Class1:dtor")
    end

    -- Class2集成于Class1
    local Class2 = class(Class1)
    function Class2:ctor( ... )
        dump("Class2:ctor")
    end
    function Class2:dtor( ... )
        dump("Class2:dtor")
    end
    -- 实例化对象
    local c1 = new(Class1)
    local c2 = new (Class2)
    -- 销毁对象
    delete(c1)
    delete(c2)

end

-- 测试dump
local function testDump()
    local data = {
        key1 = 34,
        key2 = "str",
        key3 = {
            key4 = {
                key5 = 56
            },
            key6 = 78
        }
    }
    dump(data, "this is a dump test")
end

-- 测试分模块加载
local function testLoadModule( ... )
    local moduleList = require("mvc.Loader")

    -- 卸载模块
    for k,v in pairs(moduleList) do
        delete(v)
    end
end

-- testOOP()
-- testDump()
-- testLoadModule()

-- https://blog.csdn.net/u012723995/article/details/40455357
-- 模块加载 性能分析 面向对象 组件 事件系统 数据观察追踪 回退系统 MVC
