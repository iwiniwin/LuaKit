--[[--
模块加载器
@module Loader
@author iwiniwin

Date   2019-11-15 19:20:39
Last Modified by   iwiniwin
Last Modified time 2020-01-16 13:58:34
]]
local ModuleConfig = require("mvc.module_config")

-- 根据配置读取模块
local config = {}
for k,v in pairs(ModuleConfig) do
   table.insert(config, {key = k, value = v})
end
table.sort(config, function ( a, b )
    -- 根据initOrder排序，确定加载顺序
    if a.value.initOrder and not b.value.initOrder then
        return true
    end
    if a.value.initOrder and b.value.initOrder then
        return a.value.initOrder < b.value.initOrder
    end
    return false
end)

-- 模块创建函数
local function create_module( name, params )
    params = params or {}
    assert(params.file)
    local viewClass = require(params.file)
    local view = new(viewClass)
    view._tag = {name = name, params = params}
    return view
end

-- 根据配置加载模块
local moduleList = {}
for i,v in ipairs(config) do
    if moduleList[v.key] then
        error("模块已经存在：" .. v.key)
    end
    local mod = create_module(v.key, v.value)
    moduleList[v.key] = mod
end

return moduleList