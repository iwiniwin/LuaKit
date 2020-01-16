# LuaKit
Lua核心工具包，提供对面向对象，组件系统，mvc模块化加载，事件分发系统等常用模式的封装。同时提供打印，内存泄漏检测，字符串操作等常用工具类。

部分特性介绍如下

# Contents  
- [打印复杂表结构](#dump与dumpToFile)  
- [面向对象封装](#面向对象封装)  
- [分模块加载](#分模块加载)  
- [性能分析](#性能分析)  
- [内存泄漏检测](#内存泄漏检测)  

### 打印复杂表结构
dump支持按照指定格式打印任意类型的数据
dumpToFile支持将数据序列化到文件
```lua
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
```
输出结果如下：
```
- "this is a dump test" = {
-     "key1" = 34
-     "key2" = "str"
-     "key3" = {
-         "key4" = {
-             "key5" = 56
-         }
-         "key6" = 78
-     }
- }
```
### 面向对象封装
基于Lua原表提供了`class`, `new`, `delete`等面向对象中思想中的常用函数
```lua
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
```

### 分模块加载
分模块加载是一种模块化设计思想，通过配置文件，实现对模块的按需加载。再结合mvc，可以将一个大系统，看做由多个子模块组合而成。配置了指定模块，则系统拥有该模块的功能，取消配置则不会加载该模块。
```lua
local ModuleConfig = {}

ModuleConfig.Module1 = {
    file = "mvc.module1.Test1View",
    initOrder = 2,  -- 配置模块加载顺序
}

ModuleConfig.Module2 = {
    file = "mvc.module2.Test2View",
    initOrder = 1,
}

return ModuleConfig
```

### 性能分析
通过LuaKit提供的profile工具，可以获取函数的调用情况，调用次数，调用时间，子函数调用时间等信息，以此来分析是否存在异常的函数调用或耗时操作。在需要进行性能优化时十分有用。
```lua
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
```
分析结果部分内容如下
```
Total time spent in profiled functions: 0.113s
Total call count spent in profiled functions: 12
Lua Profile output created by profiler.lua. author: myc 

-----------------------------------------------------------------------------------
| FILE                            : FUNCTION         : TIME   : %     : Call count|
-----------------------------------------------------------------------------------
| L:E:\Project\LuaKit\test.lua:61 : aaa              : 0.1130 : 100.0 :         2 |
| L:E:\Project\LuaKit\test.lua:71 : unknow           : 0.0580 : 51.3  :         1 |
| C:resume@=[C]:-1                : resume           : 0.0580 : 51.3  :         1 |
| L:E:\Project\LuaKit\test.lua:66 : ttt              : 0.0550 : 48.7  :         1 |
| C:insert@=[C]:-1                : insert           : ~      : ~     :         1 |
| C:sethook@=[C]:-1               : sethook          : ~      : ~     :         2 |
| C:coroutine_create@=[C]:-1      : coroutine_create : ~      : ~     :         1 |
| L:.\utils\profiler.lua:122      : stop             : ~      : ~     :         1 |
| C:clock@=[C]:-1                 : clock            : ~      : ~     :         1 |
| L:.\utils\profiler.lua:106      : create           : ~      : ~     :         1 |
-----------------------------------------------------------------------------------

--------------------- L:aaa@@E:\Project\LuaKit\test.lua:61 ---------------------
Call count:            2
Time spend total:       0.1130s
Time spent in children: 0.0000s
Time spent in self:     0.1130s
```

### 内存泄漏检测
对于游戏开发而言，内存泄露往往是最容易忽视的问题，很多开发者并不知道自己的代码是否存在内存泄露。此类问题可以借助MemoryMonitor来检测，具体原理是借助lua的弱引用，把某个需要观察的对象加入到弱表，如果不存在外部引用，那么在gc时候，弱表上的该对象也就自然消失，如果弱表还存在该对象，说明外部仍存在引用。
```lua
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
memoryMonitor:update()  -- 这里会打印日志

-- a不再引用b，b也被释放
a = nil
memoryMonitor:update()  -- 没有内存泄漏，这里不会打印日志
```
第一次update时存在内存泄漏，输出如下所示
```
存在以下内存泄漏：    
b@table: 02C5F7A8 = table: 02C5F7A8
请仔细检查代码！！！
```
