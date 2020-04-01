# LuaKit
Lua核心工具包，提供对面向对象，组件系统，mvc模块化加载，事件分发系统等常用模式的封装。同时提供打印，内存泄漏检测，字符串操作等常用工具类。

部分特性介绍如下，用法/测试用例请参考<a href="test.lua">这里</a>

# Contents  
- [打印复杂表结构](#打印复杂表结构)  
- [组件系统](#组件系统)  
- [事件分发系统](#事件分发系统)  
- [面向对象封装](#面向对象封装)  
- [分模块加载](#分模块加载)  
- [性能分析](#性能分析)  
- [内存泄漏检测](#内存泄漏检测)  

### 打印复杂表结构
dump支持按照指定格式打印任意类型的数据
dump_to_file支持将数据序列化到文件
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
### 组件系统
游戏开发中很多功能无法单纯靠继承实现，因为类继承会导致难以轻易改变结构，功能全都向上依赖，子类的数据爆炸，大量冗余数据和方法导致内存消耗过大。而采用组件系统，组件才是功能的携带者，可以实时增减，动态为对象增减功能。对象绑定组件就可以拥有该组件提供的功能，解绑组件则移除对应功能，通过组合构建拥有完整功能的对象，更加灵活解耦。

例如: Fly组件提供飞的能力，鸟对象绑定Fly组件就可以飞，移除Fly组件就不能飞
```lua
local ComponentBase = require("core.component.component_base")
local ComponentExtend = require("core.component.component_extend")

local A = class()
ComponentExtend(A)

-- 组件1
local Component1 = class(ComponentBase)
Component1.exportInterface = {
    {"test1"},
}
function Component1:test1( ... )
    dump("call test1 ...")
end

-- 组件2
local Component2 = class(ComponentBase)
Component2.exportInterface = {
    {"test2"},
}
function Component2:test2( ... )
    dump("call test2 ...")
end

local a = new(A)

a:bind_component(Component1)  -- 对象a绑定组件1 拥有test1方法
a:bind_component(Component2)  -- 对象a绑定组件2 拥有test2方法
a:test1()
a:test2()

a:unbind_component(Component1)  -- 解绑组件1 丧失test1方法
-- a:test1()  -- 报错 attempt to call method 'test1' (a nil value)
```
### 事件分发系统
基于观察者模式封装的一套事件分发系统

```lua
local EventSystem = new(require("core.event.event_system"))
local Event = require("core.event.event")

-- 简单用法
EventSystem:on("test", function ( ... )
    dump({...})
end)

EventSystem:emit("test", "param1", "param2")

-- 高级用法
local A = class()
function A:on_key_down( key )
    dump(key, "key name A")
end
EventSystem:on(Event.KeyDown, A.on_key_down, {target = A})

local B = class()
function B:on_key_down( key )
    dump(key, "key name B")

    return true  -- 可以中断事件派发
end

-- 后注册的事件通过提高优先级可以保证先被调用
EventSystem:on(Event.KeyDown, B.on_key_down, {target = B, priority = 2})

EventSystem:emit(Event.KeyDown, "Ctrl")

EventSystem:off_all(B)  -- 通过target取消注册

EventSystem:emit(Event.KeyDown, "Ctrl")
```
高级用法中，第一次emit时，首先触发B，B的回调返回true中断了派发，导致A的回调不会被执行，所以只打印了key name B
第二次emit时，B已经被off_all，不会触发B的回调，自然也没有人再中断事件的派发，所以只打印了key name A
输出结果如下所示：
```
- dump from: E:\Project\LuaKit\test.lua:155: in function 'func'
- "<var>" = {
-     1 = "param1"
-     2 = "param2"
- }
- dump from: E:\Project\LuaKit\test.lua:170: in function 'func'
- "key name B" = "Ctrl"
- dump from: E:\Project\LuaKit\test.lua:164: in function 'func'
- "key name A" = "Ctrl"
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
    file = "mvc.module1.test1_view",
    initOrder = 2,  -- 配置模块加载顺序
}

ModuleConfig.Module2 = {
    file = "mvc.module2.test2_view",
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
Lua Profile output created by profiler.lua. author: iwiniwin 

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
local MemoryMonitor = require("utils.memory_monitor")
local memoryMonitor = new(MemoryMonitor)

a = {}
function test( ... )
    local b = {xxx = "xxx"}
    a.b = b
    memoryMonitor:add_to_leak_monitor(b, "b")  --将b添加到内存检测工具，此时a没有被释放掉 则b也释放不掉
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
