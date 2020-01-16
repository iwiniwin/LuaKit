--[[--
观察者模式
@module ObserverPattern
@author iwiniwin

Date   2019-11-15 19:20:39
Last Modified by   iwiniwin
Last Modified time 2020-01-16 13:40:08
]]
package.path = package.path .. ";..\\?.lua;"
require("_load")
--[[
    观察者模式
    定义：
        定义了对象之间的一对多依赖，这样一来，
        当一个对象改变状态时，它的所有依赖者都会收到通知并自动更新
    优点：
        1. 主题和观察者之间是松耦合，主题只知道观察者实现了观察者接口，不需要知道
            观察者的具体是谁，做了些什么
        2. 任何时候都可以增加或删除观察者，主题不会受到任何影响
    设计原则：
        1. 为了交互对象之间的松耦合设计而努力
        松耦合的设计能让我们建立有弹性的OO系统，能够应对变化，因为 对象之间的依赖降到了最低
        2. 找出程序会变化的方面，然后将其和固定不变的方面相分离
        3. 针对接口编程，不针对实现编程
        观察者利用主题的接口注册，主题利用观察者的接口通知观察者
        4. 多用组合，少用继承
        观察者模式利用组合将许多观察者组合进主题中
    注意：
        有多个观察者时，不可以依赖特定的通知顺序
]]


--[[
    观察者模式原型
]]
-- 主题 出版者
local Subject = class()

function Subject:ctor( ... )
    -- 观察者队列
    self.observers = {}
end

-- 注册观察者
function Subject:registerObserver( observer )
    table.insert(self.observers, observer)
end

-- 移除观察者
function Subject:removeObserver( observer )
    for i,v in ipairs(self.observers) do
        if v == observer then
            table.remove(self.observers, i)
        end
    end
end

-- 通知所有的观察者对象
function Subject:notifyObservers( ... )
    -- ...参数可以是自己，拉模型，观察者通过自己这个对象去获取更新的信息
    -- 也可以是具体的状态信息，推模型（推荐这个）
    for i,v in ipairs(self.observers) do
        v:update( ... )
    end
end

-- 观察者 订阅者
local Observer = class() -- 纯接口
-- 所有观察者必须实现观察接口
function Observer:ctor( ... )
    -- 定义了update接口
    assert(self.update, "必选实现update方法")
end

--[[
    观察者模式实例
    小明和小红订阅天气信息
]]

-- 天气（主题）
local Weather = class(Subject)

-- 扩展内容 
-- 添加changed标志 java.util.Observer中有
function Weather:setChanged( ... )
    self.changed = true
end

function Weather:clearChanged( ... )
    self.changed = false
end

function Weather:hasChanged( ... )
    return self.changed
end

-- 发布天气信息
-- 利用changed的好处，使更新观察者时有更多的弹性
-- 如果没有changed则一旦天气信息有了变化就会通知观察者，太过明锐
-- 而通过changed，可以在天气变化达到某个条件时，再调用setChanged()进行有效的更新
function Weather:setWeatcherInfo( ... )
    if self.changed then
        self:notifyObservers( ... )
    end
    self.changed = false
end

-- 订阅天气的人（观察者）
local People = class(Observer)

function People:ctor( name )
    self.name = name
end

function People:update( ... )
    print(string.format("%s收到了天气信息：%s", self.name, ...))
end

-- 测试
local weather = new(Weather)

-- object.lua new实现有问题 这两个的name都是小红
local ming = new(People, "小明")
local hong = new(People, "小红")

weather:registerObserver(ming)
weather:registerObserver(hong)

-- 发布天气信息
-- 设置changed通知观察者
weather:setChanged()
weather:setWeatcherInfo("晴朗")

-- 移除一个观察者
weather:removeObserver(ming)

-- 没有设置changed，不会通知观察者
print(weather:hasChanged(), "change状态")
weather:setWeatcherInfo("阴天")

