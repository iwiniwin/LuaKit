# LuaKit
Lua核心工具包，提供对面向对象，组件系统，mvc分模块加载，事件分发系统等常用模式的封装。同时提供打印，内存泄漏检测，字符串操作等常用工具类。

部分特性介绍如下
### dump与dumpToFile
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