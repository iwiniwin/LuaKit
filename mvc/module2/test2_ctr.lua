--[[--ldoc desc
Test2Ctr 示例Ctr
@module Test2Ctr
@author iwiniwin

Date   2019-11-15 19:20:39
Last Modified by   iwiniwin
Last Modified time 2020-01-16 13:37:37
]]
local Test2Ctr = class()
Test2Ctr._class_name = "Test2Ctr"

function Test2Ctr:ctor( delegate )
    dump("load Test2Ctr")
    self.m_delegate = delegate
end

function Test2Ctr:getUI(  )
    return self.m_delegate
end

-- 刷新视图
function Test2Ctr:update_view( data )
    -- Ctr负责逻辑处理，转换视图可识别的数据
    -- data = process(data)
    
    -- 由View负责刷新视图
    local ui = self:getUI();
    if ui then
        ui:update_view(data)
    end
end

function Test2Ctr:dtor( ... )
    dump("unload Test2Ctr")
    self.m_delegate = nil
end

return Test2Ctr;