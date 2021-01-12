--[[--
适配器模式
@module CORPattern
@author iwiniwin

Date   2019-11-15 19:20:39
Last Modified by   iwiniwin
Last Modified time 2020-01-16 13:39:53
]]
package.path = package.path .. ";..\\?.lua;"
require("_load")

--[[
    适配器模式
    定义：
        将一个类的接口，转换成客户期望的另一个接口。适配器让原本接口不相容的类可以合作无间
    优点：
        可以通过创建适配器进行接口转换，让不兼容的接口编程兼容。这可以让客户从实现的接口解耦
        如果在一段时间以后，我们想改变接口，适配器可以将改变的部分封装起来，客户就不必为了应对不同的系统而每次跟着修改
]]

-- 鸭子类
local Duck = class();  
-- 鸭子有呱呱叫能力
function Duck:quack( ... )
    -- body
end
-- 鸭子有飞行能力
function Duck:fly( ... )
    -- body
end

-- 绿头鸭
local MallardDuck = class(Duck);
function MallardDuck:quack( ... )
    dump("mallard duck quack")
end
function MallardDuck:fly( ... )
    dump("mallard duck fly")
end

-- 火鸡类
local Turkey = class();
-- 火鸡有咯咯叫能力
function Turkey:gobble( ... )
    -- body
end
-- 火鸡有飞行能力
function Turkey:fly( ... )
    -- body
end

-- 野生火鸡
local WildTurkey = class(Turkey);
function WildTurkey:gobble( ... )
    dump("wild turkey gobble")
end
function WildTurkey:fly( ... )
    dump("wild turkey fly")
end

-- 适配器，让火鸡来冒充鸭子
local TurkeyAdapter = class(Duck);  -- 适配器需要实现想转换成的类型接口，也就是客户所期望看到的接口。即quack和fly
function TurkeyAdapter:ctor( turkey )
    self.turkey = turkey
end
function TurkeyAdapter:quack( ... )
    self.turkey:gobble();
end
-- 火鸡有飞行能力
function TurkeyAdapter:fly( ... )
    self.turkey:fly();
end


-------------- 测试 -------------- 

local turkey = new(WildTurkey);
local turkeyAdapter = new(TurkeyAdapter, turkey);  -- 将火鸡包装进一个火鸡适配器，使它看起来像是一只鸭子

-- 测试鸭子
local duck = turkeyAdapter;
duck:quack();  -- wild turkey gobble
duck:fly();  -- wild turkey fly