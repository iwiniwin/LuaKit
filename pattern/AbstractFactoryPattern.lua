--[[--
抽象工厂模式
@module CORPattern
@author iwiniwin

Date   2019-11-15 19:20:39
Last Modified by   iwiniwin
Last Modified time 2020-01-16 13:39:53
]]
package.path = package.path .. ";..\\?.lua;"
require("_load")


--[[
    抽象工厂模式
    定义：
        抽象工厂模式提供一个接口，用于创建相关或依赖对象的家族，而不需要明确指定具体类
    优点：
        1. 抽象工厂允许客户使用抽象的接口来创建一组相关的产品，
        而不需要知道（或关心）实际产出的具体产品是什么。这样一来，客户就从具体的产品中被解耦
    设计原则：
        1. 依赖倒置原则，依赖抽象，而不依赖具体类
]]

-- 抽象工厂，披萨原料工厂，定义一组接口用于生产产品家族。原料的获取采用了抽象工厂模式
local PizzaIngredientFactory = class();
-- 创建面团接口
function PizzaIngredientFactory:createDough( ... )
    -- body
end
-- 创建酱料接口
function PizzaIngredientFactory:createSauce( ... )
    -- body
end

-- 具体工厂类1
local NYPizzaIngredientFactory = class();
-- 实现创建面团接口
function NYPizzaIngredientFactory:createDough( ... )
    dump("create NY Ingredient Factory dough")
end
-- 实现创建酱料接口
function NYPizzaIngredientFactory:createSauce( ... )
    dump("create NY Ingredient Factory sauce")
end

-- 具体工厂类2
local ChicagoPizzaIngredientFactory = class();
-- 实现创建面团接口
function ChicagoPizzaIngredientFactory:createDough( ... )
    dump("create Chicago Ingredient Factory dough")
end
-- 实现创建酱料接口
function ChicagoPizzaIngredientFactory:createSauce( ... )
    dump("create Chicago Ingredient Factory sauce")
end

-- 抽象披萨类
local Pizza = class();
function Pizza:prepare( ... )
    -- body
end

-- 具体披萨类
local CheesePizza = class();
-- 接收PizzaIngredientFactory对象
function CheesePizza:ctor( factory )
    self.factory = factory
end
-- 实现prepare接口
function CheesePizza:prepare( ... )
    local dough = self.factory:createDough();
    local sauce = self.factory:createSauce();
end

local PizzaStore = class();

function PizzaStore:orderPizza( type )
    local pizza = self:createPizza(type);  -- 调用子类的创建披萨方法
    pizza:prepare()
    -- pizza:bake()
    -- pizza:cut()
    -- pizza:box()
    return pizza;
end

-- 声明一个抽象的工厂方法，由子类去实现。pizza的获取采用了工厂方法模式
function PizzaStore:createPizza( type )
    
end

local NYStyleCheesePizza = class();
-- 第一个子类，纽约披萨店
local NYPizzaStore = class(PizzaStore)

function NYPizzaStore:createPizza( type )
    local factory = new(NYPizzaIngredientFactory);  -- 使用具体的原料工厂
    if type == "cheese" then
        return new(CheesePizza, factory);
    end
end


local ChicagoCheesePizza = class();
-- 第二个子类，芝加哥披萨店
local ChicagoStore = class(PizzaStore)

function ChicagoStore:createPizza( type )
    local factory = new(ChicagoPizzaIngredientFactory);  -- 使用具体的原料工厂
    if type == "cheese" then
        return new(CheesePizza, factory)
    end
end

-------------- 测试 -------------- 

local store = new(ChicagoStore)
store:orderPizza("cheese")

-- create Chicago Ingredient Factory dough
-- create Chicago Ingredient Factory sauce