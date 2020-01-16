--[[--ldoc desc
Test2View 示例View
@module Test2View
@author iwiniwin

Date   2019-11-15 19:20:39
Last Modified by   iwiniwin
Last Modified time 2020-01-16 13:59:57
]]
local Test2Ctr = require("mvc.module2.test2_ctr")
local Test2View = class()
Test2View._className = "Test2View"

function Test2View:ctor( ... )
    dump("load Test2View")
    self:bindCtr()
end

function Test2View:bindCtr(  )
    if self.mCtr then
        return false
    else
        self.mCtr = new(Test2Ctr, self)
        return true
    end
end

function Test2View:getCtr( ... )
    return self.mCtr
end

-- 更新视图
function Test2View:updateView( data )
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

function Test2View:unBindCtr( ... )
    if self.mCtr then
        delete(self.mCtr)
        self.mCtr = nil
    end
end

function Test2View:dtor( ... )
    dump("unload Test2View")
    self:unBindCtr()
end

return Test2View;