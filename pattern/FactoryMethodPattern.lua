--[[--
工厂方法模式
@module FactoryMethodPattern
@author iwiniwin

Date   2019-11-15 19:20:39
Last Modified by   iwiniwin
Last Modified time 2020-01-16 13:39:53
]]
package.path = package.path .. ";..\\?.lua;"
require("_load")


--[[
    简单工厂模式，不是一个真正的模式，但经常被用于封装创建对象的代码
]]

local CheesePizza = class();  -- 芝士披萨
local PepperoniPizza = class();  -- 意大利香肠披萨

local SimplePizzaFactory = class() 

-- 简单工厂，根据传入的参数，决定创建出哪一种产品类的实例
SimplePizzaFactory.createPizza = function ( type )
    if type == "cheese" then
        return new(CheesePizza) 
    elseif type == "pepperoni" then
        return new(PepperoniPizza)
    end
end

--[[
    工厂方法模式
    定义：
        定义了一个创建对象的接口，但由子类决定要实例化的类是哪一个。
        工厂方法让类把实例化推迟到子类
    优点：
        1. 通过让子类决定该创建的对象是什么，来达到将对象创建的过程封装的目的
    设计原则：
        1. 依赖倒置原则，依赖抽象，而不依赖具体类
]]

local PizzaStore = class();

function PizzaStore:orderPizza( type )
    local pizza = self:createPizza(type);  -- 调用子类的创建披萨方法
    -- pizza:prepare()
    -- pizza:bake()
    -- pizza:cut()
    -- pizza:box()
    return pizza;
end

-- 声明一个抽象的工厂方法，由子类去实现。实例化的责任被移到一个方法中，此方法就如同是一个工厂
function PizzaStore:createPizza( type )
    -- body
end

local NYStyleCheesePizza = class();
-- 第一个子类，纽约披萨店
local NYPizzaStore = class(PizzaStore)

function NYPizzaStore:createPizza( type )
    if type == "cheese" then
        dump("create ny cheese pizza")
        return new(NYStyleChesePizza);
    end
end


local ChicagoCheesePizza = class();
-- 第二个子类，芝加哥披萨店
local ChicagoStore = class(PizzaStore)

function ChicagoStore:createPizza( type )
    if type == "cheese" then
        dump("create chicago cheese pizza")
        return new(ChicagoCheesePizza)
    end
end

-------------- 测试 -------------- 

local store = new(ChicagoStore)
store:orderPizza("cheese")  -- create chicago cheese pizza