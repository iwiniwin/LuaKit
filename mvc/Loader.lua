--[[--模块加载器
@author LeirZhang

Date   2019-11-15 19:20:39
Last Modified by   LeirZhang
Last Modified time 2019-11-15 19:22:12
]]
local ModuleConfig = require("mvc.ModuleConfig")

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
local function createModule( name, params )
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
    local mod = createModule(v.key, v.value)
    moduleList[v.key] = mod
end

return moduleList