--[[--Test1View 示例View
@author LeirZhang

Date   2019-11-15 19:20:39
Last Modified by   LeirZhang
Last Modified time 2019-11-15 19:22:12
]]
local Test1Ctr = require("mvc.module1.Test1Ctr")
local Test1View = class()
Test1View._className = "Test1View"

function Test1View:ctor( ... )
    dump("load Test1View")
    self:bindCtr()
end

function Test1View:bindCtr(  )
    if self.mCtr then
        return false
    else
        self.mCtr = new(Test1Ctr, self)
        return true
    end
end

function Test1View:getCtr( ... )
    return self.mCtr
end

-- 更新视图
function Test1View:updateView( data )
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

function Test1View:unBindCtr( ... )
    if self.mCtr then
        delete(self.mCtr)
        self.mCtr = nil
    end
end

function Test1View:dtor( ... )
    dump("unload Test1View")
    self:unBindCtr()
end

return Test1View;