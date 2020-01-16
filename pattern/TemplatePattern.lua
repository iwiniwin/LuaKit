--[[--模板方法模式
@module TemplatePattern
@author iwiniwin

Date   2019-11-15 19:20:39
Last Modified by   iwiniwin
Last Modified time 2020-01-16 13:41:10
]]
package.path = package.path .. ";..\\?.lua;"
require("_load")
--[[
    模板方法模式
    定义：

        在一个方法中定义一个算法的骨架，而将一些步骤延迟到子类中。
        模板方法使得子类可以在不改变算法结构的情况下，重新定义算法中的某些步骤
    优点：
        1. 对算法有更多的控制权，超类主导一切，拥有且保护这个算法
        2. 超类的存在将代码的复用最大化，算法只存在超类中，容易修改
        3. 模板方法提供了一个框架，可以让各种子类插进来，不同的子类实现自己的方法就可以
    设计原则：
        好莱坞原则：别调用我们，我们会调用你
        允许底层组件将自己挂钩到系统上，但是高层组件会决定什么时候和怎样使用这些底层组件
]]


--[[
    模板方法模式原型
]]
local SuperClass = class()

function SuperClass:templateMethod( ... )
    -- 模板方法 子类不应该覆盖它

    assert(self.primitiveOperation1, "子类必须实现primitiveOperation1")
    assert(self.primitiveOperation2, "子类必须实现primitiveOperation2")

    self.primitiveOperation1()
    self.primitiveOperation1()

    self.concreteOperation()

    self.hook()
end

function SuperClass:concreteOperation( ... )
    -- 在超类中具体实现，子类不应该覆盖
    -- 可以被模板方法直接使用，或者被子类使用
end

function SuperClass:hook( ... )
    -- 一个具体方法，但什么也不做
    -- 钩子方法，子类可以根据情况决定要不要覆盖他
    -- 如果算法的这个部分是可选的，就用钩子
    -- 钩子可以让子类能够有机会对模板方法中某些即将发生的步骤做出反应
end

--[[
    模板方法模式实例
    封装一个制作饮品的具体算法
]]

local Drink = class()

function Drink:prepareDrink( ... )

    assert(self.brew)
    assert(self.addCondiments)

    -- 煮沸水
    self.boilWater()
    -- 冲泡
    self.brew()
    -- 倒入杯中
    self.pourInCap()
    -- 添加调料
    if self:wantsCondiments() then
        self.addCondiments()
    end
end

function Drink:boilWater( ... )
    print("把水煮沸。。。")
end

function Drink:pourInCap( ... )
    print("倒入杯中。。。")
end

function Drink:wantsCondiments( ... )
    -- 钩子方法
    return true
end
-- 子类

local Coffee = class(Drink)

function Coffee:brew( ... )
    print("用沸水冲泡咖啡粉")
end

function Coffee:addCondiments( ... )
    print("添加牛奶和糖")
end


local coffee = new(Coffee)
coffee:prepareDrink()

local Tea = class(Drink)

function Tea:brew( ... )
    print("用沸水浸泡茶叶")
end

function Tea:addCondiments( ... )
    print("添加柠檬")
end

local tea = new(Tea)
tea:prepareDrink()

-- 不加调料的茶

local TeaNoCondiments = class(Drink)

function TeaNoCondiments:brew( ... )
    print("用沸水浸泡茶叶")
end

function TeaNoCondiments:addCondiments( ... )
    print("添加柠檬")
end

function TeaNoCondiments:wantsCondiments( ... )
    return false
end

local tea = new(Tea)
tea:prepareDrink()