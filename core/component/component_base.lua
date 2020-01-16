--[[--组件基类  
注意：所有组件必须继承该类
@module ComponentBase
@author iwiniwin

Date   2020-01-16 13:27:14
Last Modified by   iwiniwin
Last Modified time 2020-01-16 13:45:20
]]
local ComponentBase = class()

ComponentBase._className = "ComponentBase"

function ComponentBase:ctor( componentName, depends, priority )
    -- body
end
