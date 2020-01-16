--[[--
LuaKit测试用例
@module test
@author iwiniwin

Date   2019-11-15 19:20:39
Last Modified by   iwiniwin
Last Modified time 2020-01-16 13:43:51
]]
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

-- 测试性能分析
local function testProfile( ... )
    local new_profiler = require("utils.profiler")
    local profiler = new_profiler("call")
    profiler:start()  -- 开启性能分析

    local function aaa(  )
        for i = 1, 10000000 do

        end
    end
    local function ttt(  )
        aaa()
    end
    ttt()

    -- 同时支持分析协程内的函数调用情况
    local co = coroutine.create(function ( ... )
        aaa()
    end)
    coroutine.resume(co)

    profiler:stop()  -- 停止性能分析
    -- 输出分析结果到文件
    profiler:dump_report_to_file("profile.txt")
end

-- 测试内存泄漏检测工具
local function testMemoryMonitor( ... )
    local MemoryMonitor = require("utils.MemoryMonitor")
    local memoryMonitor = new(MemoryMonitor)

    a = {}
    function test( ... )
        local b = {xxx = "xxx"}
        a.b = b
        memoryMonitor:addToLeakMonitor(b, "b")  --将b添加到内存检测工具，此时a没有被释放掉 则b也释放不掉
    end
    test()

    -- 由于a在引用b，因此b存在内存泄漏
    memoryMonitor:update()

    -- a不再引用b，b也被释放
    a = nil
    memoryMonitor:update()  -- 没有内存泄漏，这里不会打印日志
end

-- testOOP()
-- testDump()
-- testLoadModule()
-- testProfile()
testMemoryMonitor()

-- 组件 事件系统 数据观察追踪 回退系统
