--[[
    lua内存泄漏检测工具
    原理：弱表中的引用是弱引用，不会导致对象的引用计数发生变化
    即如果一个对象只有弱引用指向它，那么gc会自动回收该对象的内存
]]

package.path = package.path .. ";..\\?.lua;"
require("_load")

-- 监控间隔配置（单位：秒）
local MonitorConfig = {
    -- 内存泄漏监控间隔
    memLeakInterval = 1,
}

local MemoryMonitor = {}

function MemoryMonitor:ctor( ... )
    -- 内存泄漏弱引用表
    self.__memLeakTable = {}
    -- mode字段可以取 k, v, kv 分别表示table中的 key, value，是弱引用的， kv就是二者的组合
    -- 对于一个table，任何情况下，只要它的key或者value中的一个被gc，那么这个key-value pair就从表中移除了
    setmetatable(self.__memLeakTable, {__mode = "kv"})
    -- 内存泄漏监控器
    self.__memLeakMonitor = nil

    self:start()
end

-- 开始检测
function MemoryMonitor:start( ... )
    self.__memLeakMonitor = self:__memLeakMonitoring()
end


--[[
把一个表或者对象添加到内存检测工具中，如果该表或者对象不存在外部引用，则说明释放干净
否则内存泄漏工具会输出工具
@table t 观察的对象 表
@string tName 表的别名

@usage 
local memoryMonitor = new(MemoryMonitor)
memoryMonitor:addToLeakMonitor(self, "xx模块")
]]
function MemoryMonitor:addToLeakMonitor( t, tName )
    if not self.__memLeakMonitor then
        return
    end

    assert("string" == type(tName), "invalid params")

    -- 必须以名字+地址的方式作为键值
    -- 内存泄漏经常是一句代码多次分配出内存而忘了回收，因此tName经常是相同的
    local name = string.format("%s@%s", tName, tostring(t))
    if nil == self.__memLeakTable[name] then
        self.__memLeakTable[name] = t
    end
end

-- 更新弱表信息
function MemoryMonitor:update( dt )
    dt = dt or 10
    if self.__memLeakMonitor then
        self.__memLeakMonitor(dt)
    end
end



function MemoryMonitor:__memLeakMonitoring( ... )
    local monitorTime = MonitorConfig.memLeakInterval
    local interval = MonitorConfig.memLeakInterval
    local str = nil
    return function( dt )
        interval = interval + dt
        if interval >= monitorTime then
            interval = interval - monitorTime

            -- 强制调用gc
            collectgarbage("collect")
            collectgarbage("collect")
            collectgarbage("collect")
            collectgarbage("collect")

            local flag = false
            -- 打印当前内存泄漏监控表中依然存在（没有被释放）的对象信息
            str = "存在以下内存泄漏："
            for k,v in pairs(self.__memLeakTable) do
                str = str .. string.format("    \n%s = %s", tostring(k), tostring(v))
                flag = true
            end
            str = str .. "\n请仔细检查代码！！！"
            if flag then
                print(str)
            end
        end
    end
end


--测试代码

a = {}

local memoryMonitor = new(MemoryMonitor)

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
memoryMonitor:update()


--[[
-- TODO 待研究情况
print("--------------分隔符--------------")
a = {}

local b = {xxx = "xxx"}

a.b = b

memoryMonitor:addToLeakMonitor(b, "b")

a = nil
-- 此时b仍然没有被释放掉
-- 可能是由于b是local变量，不仅有a在引用b，可能lua的堆栈也在对其引用，导致无法被释放。
-- 可以对比上面在函数里定义b的区别
memoryMonitor:update()
--]]
