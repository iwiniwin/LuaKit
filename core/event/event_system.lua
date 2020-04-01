--[[--事件分发系统
@module EventSystem
@author iwiniwin

Date   2020-03-30 14:23:50
Last Modified by   iwiniwin
Last Modified time 2020-04-01 16:18:51
]]
local EventSystem = class()

local id = 1

EventSystem._class_name = "EventSystem"


function EventSystem:ctor(  )
    self._listeners = {}
end

function EventSystem:dtor(  )
    self._listeners = nil
end

function EventSystem:on( event, func, params )
    event = tostring(event)
    if not self._listeners[event] then
        self._listeners[event] = {list = {}, emit_count = 0}
    end
    local event_listener = self._listeners[event]

    params = params or {}
    local priority = params.priority or 0
    local target = params.target
    
    for i,cb in ipairs(event_listener.list) do
        if cb.target == target and cb.func == func then
            error("register the same callback multiple times")
        end
    end

    local cb = {target = target, func = func, id = id, priority = priority}
    table.insert(event_listener.list, cb)

    id = id + 1

    if priority > 0 then
        event_listener.need_sort = true
        self:sort(event_listener) -- 排序
    end
end

function EventSystem:off( event, func, params )
    event = tostring(event)
    if not self._listeners[event] then
        return 
    end
    local event_listener = self._listeners[event]

    params = params or {}

    for i,cb in ipairs(event_listener.list) do
        if cb.func == func and cb.target == params.target then
            if event_listener.emit_count > 0 then
                cb.need_remove = true
                event_listener.need_clean = true
            else
                table.remove(event_listener.list, i)
            end
            break;
        end
    end
end

function EventSystem:off_all( target )
    for event,listener in pairs(self._listeners) do

        for i,cb in ipairs(listener.list) do
            if cb.target == target then
                cb.need_remove = true
            end
        end

        listener.need_clean = true
        self:clean(listener)
    end
end

function EventSystem:emit( event, ... )
    event = tostring(event)
    if not self._listeners[event] then
        return 
    end
    local event_listener = self._listeners[event]

    local interrupt = false
    for i = 1, #event_listener.list do
        if interrupt == true then
            break
        end
        local cb = event_listener.list[i]
        if cb.func and cb.need_remove ~= true then
            event_listener.emit_count = event_listener.emit_count + 1
            if cb.target then
                interrupt = cb.func(cb.target, ...)
            else
                interrupt = cb.func(...)
            end
            event_listener.emit_count = event_listener.emit_count - 1
        end
    end

    self:sort(event_listener);
    self:clean(event_listener);

    return interrupt
end

function EventSystem:sort( listener )
    if listener.need_sort == true and listener.emit_count == 0 then

        table.sort(listener.list, function ( a, b )
            if a.priority == b.priority then
                return a.id < b.id
            else
                return a.priority > b.priority
            end
        end)

        listener.need_sort = false;
    end
end

function EventSystem:clean( listener )
    if listener.need_clean == true and listener.emit_count == 0 then
        for i = #listener.list, 1, -1 do
            if listener.list[i].need_remove then
                table.remove(listener.list, i)
            end
        end
        listener.need_clean = false;
    end
end

function EventSystem:update_priority( event, func, params )
    event = tostring(event)
    if not self._listeners[event] then
        return 
    end
    local event_listener = self._listeners[event]

    params = params or {}
    local priority = params.priority or 0
    for i,cb in ipairs(event_listener.list) do
        if cb.func == func and cb.target == params.target then
            cb.priority = priority
            event_listener.need_sort = true
            self:sort(event_listener);
            break;
        end
    end
end

return EventSystem