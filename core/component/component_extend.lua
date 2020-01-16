--[[--组件扩展
赋予类绑定解绑组件的能力
@module ComponentExtend
@author iwiniwin

Date   2020-01-16 13:27:14
Last Modified by   iwiniwin
Last Modified time 2020-01-16 13:45:20
]]
local ComponentBase = require("core.component.component_base")
local ComponentFactory = require("component_factory")

local component_extend = function ( Class )

    function Class:has_component( ComponentClass )
        local component_name = tostring(ComponentClass)
        return self._component_objects and self._component_objects[component_name]
    end

    function Class:bind_component( ComponentClass )
        assert(typeof(ComponentClass, ComponentBase), "required componnet class")
        local component_name = tostring(ComponentClass);
        if not self._component_objects then self._component_objects = {} end
        if self._component_objects[component_name] then return end

        local componnet = ComponentFactory.create_component(ComponentClass);
        for i,DependComponentClass in ipairs(component.depends) do
            local depend_component_name = tostring(DependComponentClass)
            self:bind_component(DependComponentClass)

            if not self._component_depends then self._component_depends = {} end
            if not self._component_depends[component_name] then
                self._component_depends[component_name] = {}
            end
            table.insert(self._component_depends[component_name], depend_component_name)
        end

        componnet:bind(self)
        self._component_objects[component_name] = componnet
        self:reset_all_behaviors()

        return componnet
    end

    function Class:unbind_component( ComponentClass )
        local component_name = tostring(ComponentClass);
        assert(self._component_objects and self._component_objects[component_name],
            string.format("componnet %s not binding", component_name))
        assert(not self._component_depends and not self._component_objects[component_name],
            string.format("component %s depends by other binding", component_name))

        -- local component = self._component_objects[component_name];
        
    end

end

return component_extend