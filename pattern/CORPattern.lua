--[[--
责任链模式
@module CORPattern
@author iwiniwin

Date   2019-11-15 19:20:39
Last Modified by   iwiniwin
Last Modified time 2020-01-16 13:39:53
]]
package.path = package.path .. ";..\\?.lua;"
require("_load")
--[[
    责任链模式
    定义：
        将接收者对象连成一条链，并在该链上传递请求，直到有一个接收者对象处理它
        通过让更多对象有机会处理请求，避免了请求发送者和接收者之间的耦合
    使用场景：
        经常被用在窗口系统中，处理鼠标和键盘之类的事件
    优点：
        1. 将请求的发送者和接收者解耦
        2. 通过改变链内的成员或调动它们的次序，允许动态地新增或者删除责任
    缺点：
        1. 内存消耗，链上的所有对象都需要创建，可能有些对象根本不会被用到（或很少走进满足该对象处理的条件）
        2. 性能消耗，处理需要一层层的传递，才能被正确的对象所处理
]]


--[[
    责任链模式实例
    客户到售楼处买房，请求折扣的例子
]]
-- 价格处理类
local PriceHandler = class()

function PriceHandler:ctor( ... )
    -- 抽象方法 processDiscount
    assert(self.processDiscount, "子类必须实现processDiscount接口")
end

function PriceHandler:setSuccessor( successor )
    self.successor = successor
end

-- 目前是三个Handler，sale销售 和 manager经理 和 ceo

local Sale = class(PriceHandler)
Sale._class_name = "Sale"

function Sale:processDiscount( discount )
    if discount < 0.2 then
        print("sale处理了" .. discount .. "的折扣")
    else
        self.successor:processDiscount(discount)
    end
end

local Manager = class(PriceHandler)
Manager._class_name = "Manager"

function Manager:processDiscount( discount )
    if discount < 0.4 then
        print("manager处理了" .. discount .. "的折扣")
    else
        self.successor:processDiscount(discount)
    end
end

local CEO = class(PriceHandler)

function CEO:processDiscount( discount )
    if discount < 0.8 then
        print("ceo处理了" .. discount .. "的折扣")
    else
        print("ceo拒绝了" .. discount .. "的折扣")
    end
end

-- PriceHandler工厂类
-- 添加一个工厂类提供createPriceHandler方法，
-- 而不直接在PriceHandler中提供的原因是基于单一职责原则，
-- PriceHandler见名知意是用于价格处理的，而不应该有提供PriceHandler的功能
local PriceHandlerFactor = class()

function PriceHandlerFactor.createPriceHandler( ... )
    -- 构造责任链
    local sale = new(Sale)
    local manager = new(Manager)
    local ceo = new(CEO)
    -- 销售设置后继是经理
    sale:setSuccessor(manager)
    -- 经理的后继是ceo
    manager:setSuccessor(ceo)
    -- ceo不存在直接后继

    -- 由sale优先处理
    return sale
end


-- 顾客
local Customer = class()

function Customer:setPriceHandler( priceHandler )
    self.priceHandler = priceHandler
end

function Customer:requestDiscount( discount )
    self.priceHandler:processDiscount(discount)
end


-- 测试
local customer = new(Customer)

customer:setPriceHandler(PriceHandlerFactor.createPriceHandler())

for i = 1, 10 do 
    -- 100次折扣申请
    customer:requestDiscount(math.random())
end

-- 如何应对变化
-- 如果此时ceo希望添加一个vp的角色，帮他审核0.5以下的折扣
-- 只需要添加一个vp类，同时修改以下工厂方法
print("加入一个vp角色")

local VP = class(PriceHandler)

function VP:processDiscount( discount )
    if discount < 0.6 then
        print("vp处理了" .. discount .. "的折扣")
    else
        self.successor:processDiscount(discount)
    end
end

function PriceHandlerFactor.createPriceHandler( ... )
    local sale = new(Sale)
    local manager = new(Manager)
    local ceo = new(CEO)
    -- 添加一个vp
    local vp = new(VP)
    -- 销售设置后继是经理
    sale:setSuccessor(manager)

    -- 修改经理的后继为vp
    manager:setSuccessor(vp)

    -- vp的后继为ceo
    vp:setSuccessor(ceo)
    -- ceo不存在直接后继

    -- 由sale优先处理
    return sale
end


-- 测试
local customer = new(Customer)

customer:setPriceHandler(PriceHandlerFactor.createPriceHandler())

for i = 1, 10 do 
    -- 100次折扣申请
    customer:requestDiscount(math.random())
end


