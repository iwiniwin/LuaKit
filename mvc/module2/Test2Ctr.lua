--[[--Test2Ctr 示例Ctr
@author LeirZhang

Date   2019-11-15 19:20:39
Last Modified by   LeirZhang
Last Modified time 2019-11-15 19:22:12
]]
local Test2Ctr = class()
Test2Ctr._className = "Test2Ctr"

function Test2Ctr:ctor( delegate )
    dump("load Test2Ctr")
    self.mDelegate = delegate
end

function Test2Ctr:getUI(  )
    return self.mDelegate
end

-- 刷新视图
function Test2Ctr:updateView( data )
    -- Ctr负责逻辑处理，转换视图可识别的数据
    -- data = process(data)
    
    -- 由View负责刷新视图
    local ui = self:getUI();
    if ui then
        ui:updateView(data)
    end
end

function Test2Ctr:dtor( ... )
    dump("unload Test2Ctr")
    self.mDelegate = nil
end

return Test2Ctr;