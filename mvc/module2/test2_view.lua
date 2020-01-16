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
Test2View._class_name = "Test2View"

function Test2View:ctor( ... )
    dump("load Test2View")
    self:bind_ctr()
end

function Test2View:bind_ctr(  )
    if self.mCtr then
        return false
    else
        self.mCtr = new(Test2Ctr, self)
        return true
    end
end

function Test2View:get_ctr( ... )
    return self.mCtr
end

-- 更新视图
function Test2View:update_view( data )
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

function Test2View:unbind_ctr( ... )
    if self.mCtr then
        delete(self.mCtr)
        self.mCtr = nil
    end
end

function Test2View:dtor( ... )
    dump("unload Test2View")
    self:unbind_ctr()
end

return Test2View;