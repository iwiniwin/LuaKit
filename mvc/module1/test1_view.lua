--[[--ldoc desc
Test1View 示例View
@module Test1View
@author iwiniwin

Date   2019-11-15 19:20:39
Last Modified by   iwiniwin
Last Modified time 2020-01-16 14:00:03
]]
local Test1Ctr = require("mvc.module1.test1_ctr")
local Test1View = class()
Test1View._class_name = "Test1View"

function Test1View:ctor( ... )
    dump("load Test1View")
    self:bind_ctr()
end

function Test1View:bind_ctr(  )
    if self.mCtr then
        return false
    else
        self.mCtr = new(Test1Ctr, self)
        return true
    end
end

function Test1View:get_ctr( ... )
    return self.mCtr
end

-- 更新视图
function Test1View:update_view( data )
    -- 数据驱动
    -- 视图与逻辑分离，数据有什么就更新什么
    if data.title then
        -- 更新title
    end
    if data.content then
        -- 更新content
    end
    if data.other then
        -- 更新other
    end
end

function Test1View:unbind_ctr( ... )
    if self.mCtr then
        delete(self.mCtr)
        self.mCtr = nil
    end
end

function Test1View:dtor( ... )
    dump("unload Test1View")
    self:unbind_ctr()
end

return Test1View;