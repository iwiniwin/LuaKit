--[[--Test1Ctr 示例Ctr
@module Test1Ctr
@author iwiniwin

Date   2019-11-15 19:20:39
Last Modified by   iwiniwin
Last Modified time 2020-01-16 13:44:50
]]
local Test1Ctr = class()
Test1Ctr._class_name = "Test1Ctr"

function Test1Ctr:ctor( delegate )
    dump("load Test1Ctr")
    self.m_delegate = delegate
end

function Test1Ctr:get_ui(  )
    return self.m_delegate
end

-- 刷新视图
function Test1Ctr:update_view( data )
    -- Ctr负责逻辑处理，转换视图可识别的数据
    -- data = process(data)
    
    -- 由View负责刷新视图
    local ui = self:get_ui();
    if ui then
        ui:update_view(data)
    end
end

function Test1Ctr:dtor( ... )
    dump("unload Test1Ctr")
    self.m_delegate = nil
end

return Test1Ctr;