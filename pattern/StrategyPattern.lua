--[[--策略模式
@module StrategyPattern
@author iwiniwin

Date   2019-11-15 19:20:39
Last Modified by   iwiniwin
Last Modified time 2020-01-16 13:40:54
]]
package.path = package.path .. ";..\\?.lua;"
require("_load")
--[[
    策略模式
    定义：
        将可变的部分从程序中抽象分离成算法接口
        在该接口下分别封装一系列算法实现，并使他们可以相互替换
        从而导致客户端程序独立于算法的改变
    优点：
        1. 足够灵活，不同的策略只需要给出封装的接口的不同实现即可，富有弹性，可以较好地应对变化
        2. 复用代码，更易于维护，可以复用相同的策略
        3. 消除大量的条件语句
    缺点：
        1. 增加了对象的数目
        2. 客户代码需要了解策略的具体细节
    设计原则：
        1. 找出应用中需要变化的部分，把他们独立出来，不要和那些不需要变化的代码混在一起
        鸭子的飞行行为是千变万化的，但是鸭子具有飞行行为是不变的，
        将这个不变的部分抽象为飞行策略接口，而具体的飞行行为交给子类去实现
        2. 面向接口编程，而不是面向实现编程
        不如鸭子超类只是持有了飞行策略接口，而不是具体的飞行实现
        3. 多用组合，少用继承
]]


--[[
    策略模式原型
]]
local Super = class()
function Super:ctor( ... )
    -- body
end

function Super:setStrategy( strategy )
    -- 通过组合注入策略
    self.strategy = strategy
end

function Super:interface( ... )
    -- 通过策略实现某个功能
    self.strategy:interface()
end

-- 策略接口
local Strategy = class()
function Strategy:ctor( ... )
    -- 声明了某个策略接口
    assert(self.interface, "必须实现某策略")
end


--[[
    策略模式实例
    有一个鸭子的父类，已经有一个正常鸭子的实现，后面需要再实现橡皮鸭（不会飞），太空鸭（坐火箭飞）
]]

-- 鸭子超类
local Duck = class()
-- 鸭子都有一个外观
function Duck:display( ... )

end

function Duck:setFlyStrategy( flyStrategy )
    self.flyStrategy = flyStrategy
end

function Duck:fly( ... )
    self.flyStrategy:fly()
end

-- 飞行策略接口
local FlyStrategy = class()
function FlyStrategy:ctor( ... )
    assert(self.fly, "必须实现飞行接口")
end


-- 具体飞行策略

-- 振翅高飞
local FlyWithWin = class(FlyStrategy)
function FlyWithWin:fly( ... )
    print("振翅高飞")
end
local flyWithWin = new(FlyWithWin)


-- 正常鸭
local NormalDuck = class(Duck)
function NormalDuck:ctor( ... )
    self:setFlyStrategy(flyWithWin)
end
function NormalDuck:display( ... )
    print("我是正常鸭")
end

-- 测试
local normalDuck = new(NormalDuck)
normalDuck:display()
normalDuck:fly()


-- 不会飞（也是一种飞行策略）
local FlyNoWay = class(FlyStrategy)
function FlyWithWin:fly( ... )
    print("不会飞")
end
local flyNoWay = new(FlyNoWay)

-- 橡皮鸭
local RubberDuck = class(Duck)
function RubberDuck:ctor( ... )
    self:setFlyStrategy(flyNoWay)
end
function RubberDuck:display( ... )
    print("我是橡皮鸭")
end

-- 测试
local rubberDuck = new(RubberDuck)
rubberDuck:display()
rubberDuck:fly()


-- 坐火箭飞
local FlyWithRocket = class(FlyStrategy)
function FlyWithRocket:fly( ... )
    print("坐火箭飞")
end
local flyWithRocket = new(FlyWithRocket)

-- 太空鸭
local SpaceDuck = class(Duck)
function SpaceDuck:ctor( ... )
    self:setFlyStrategy(flyWithRocket)
end
function SpaceDuck:display( ... )
    print("我是正常鸭")
end

-- 测试
local spaceDuck = new(SpaceDuck)
spaceDuck:display()
spaceDuck:fly()

-- 对于鸭子超类，没有在其中直接定义fly方法，或者fly接口的原因
-- 不直接定义fly方法，不是所有的鸭子都会飞，对于不会飞的鸭子需要覆盖该方法，但是可能会由于某些原因忘记覆盖
-- 不直接定义fly接口，这样的话，所有的子类都必须要实现该接口，
-- 而且代码无法复用，重复代码多，比如同一个飞行策略，在具有相同的策略的子类中都要写一遍

-- 采用策略模式的好处，灵活不同的策略可以有不同的实现，当某些子类有共同的飞行策略，还可以直接复用该策略

