--[[
    lua性能分析工具
]]
--[[
    debug.getinfo(level, arg) : 返回一个包含函数信息的table
    level表示函数调用的层级，表示要输出哪个函数的信息
    arg是一个字符串，其中每个字符代表一组字段，用于指定希望获取那些信息，可以是"n","S","I","u","f","L"中的一个或组合
    n : 表示name（函数名）和namewhat（函数类型，field, upvalue, global）
    S : 表示source（函数所属文件名）, linedefined（函数定义起始行号）, lastlinedefined（函数定义结束行号）, what（函数类型，Lua, C, main）, short_src（函数所属文件名，source的短版本）
    l : 表示currentline（上级函数被调用的行号）
    u : 表示nups（函数的upvalue值的个数）
    f : 表示func（函数本身）
    L : 表示activelines（一个包含行号的table，可理解为该函数运行的代码的行号）
    debug.sethook(hook, mask, count) : 将一个函数作为钩子函数设入。字符串mask以及数字count决定了钩子将在何时调用
    掩码是由下列字符组合成的字符串
    "c" : 每当lua调用一个函数时，调用钩子
    "r" : 每当lua从一个函数内返回时，调用钩子
    "l" : 每当lua进入新的一行时，调用钩子
    当count值大于0的时候，每执行完count数量的指令后就会触发钩子

]]
package.path = package.path .. ";..\\?.lua;"
require("_load")

local Profiler = {}

--[[
创建一个性能分析工具对象
@string variant 性能分析模式 "call" or "time"
@usage
local profiler = new_profiler("call")
profiler:start()
-- do something
profiler:stop()
profiler:dump_report_to_file("profile.txt")
]]
local function new_profiler( variant )
    if Profiler.running then
        print("Profiler already running")
        return
    end

    variant = variant or "time"

    if variant ~= "time" and variant ~= "call" then
        print("Profiler method must be 'time' or 'call'")
        return
    end

    local newprof = {}
    for k,v in pairs(Profiler) do
        newprof[k] = v
    end
    newprof.variant = variant
    return newprof
end

--[[
启动性能分析，核心是利用debug.sethook对函数调用进行钩子
每次只能启动一个
]]
function Profiler:start( ... )
    if Profiler.running then
        return
    end
    Profiler.running = self

    self.caller_cache = {}
    self.callstack = {}

    self.start_time = os.clock()
    if self.variant == "time" then

    elseif self.variant == "call" then 
        -- 因为垃圾回收会导致性能分析下降严重，所以先放缓垃圾回收
        self.setpause = collectgarbage("setpause")
        self.setstepmul = collectgarbage("setstepmul")
        collectgarbage("setpause", 300)
        collectgarbage("setstepmul", 5000)
        debug.sethook(profiler_hook_wrapper_by_call, "cr")
    else
        error("Profiler method must be 'time' or 'call'")
    end
end

--[[
    停止性能分析
]]
function Profiler:stop( ... )
    if Profiler.running ~= self then
        -- 如果没有启动则没有任何效果
        return
    end
    self.end_time = os.clock()
    -- 停止性能分析
    debug.sethook(nil)
    if self.variant == "call" then
        -- 还原之前的垃圾回收设置
        collectgarbage("setpause", self.setpause) 
        collectgarbage("setstepmul", self.setstepmul)
    end
    collectgarbage("collect")
    collectgarbage("collect")
    Profiler.running = nil
end

--[[
    钩子函数入口
]]
function profiler_hook_wrapper_by_call( action )
    if Profiler.running == nil then
        debug.sethook(nil)
    end
    Profiler.running:analysis_call_info(action)
end

--[[
    分析函数调用信息
    @string action 函数调用类型 action return tail return
]]
function Profiler:analysis_call_info( action )
    -- 获取当前的调用信息，注意该函数有一定的损耗
    -- 0表示当前函数，即getinfo，1表示上一层调用即analysis_call_info，2表示再上一层，即profiler_hook_wrapper_by_call， 3即客户函数
    local caller_info = debug.getinfo(3, "Slfn")

    if caller_info == nil then
        return
    end

    local last_caller = self.callstack[1]

    if action == "call" then -- 进入函数，标记堆栈
        local this_caller = self:get_func_info_by_cache(caller_info)
        this_caller.parent = last_caller
        this_caller.clock_start = os.clock()
        this_caller.count = this_caller.count + 1
        table.insert(self.callstack, 1, this_caller)
    else
        table.remove(self.callstack, 1) -- 移除顶部堆栈，有可能粗发连续触发return

        if action == "tail return" then
            return
        end

        local this_caller = self.caller_cache[caller_info.func]
        if this_caller == nil then
            return
        end

        -- 计算本次函数调用时长
        this_caller.this_time = os.clock() - this_caller.clock_start 
        -- 该函数累加调用时间
        this_caller.time = this_caller.time + this_caller.this_time  

        -- 更新父类信息
        if this_caller.parent then
            local func = this_caller.func
            -- 更新父类中存储的该子函数的调用次数
            this_caller.parent.children[func] = (this_caller.parent.children[func] or 0) + 1
            -- 更新父类中存储的该子函数的总调用时间
            this_caller.parent.children_time[func] = (this_caller.parent.children_time[func] or 0) + this_caller.this_time
            
            if caller_info.name == nil then
                -- 统计无名函数调用时间
                this_caller.parent.unknow_child_time = this_caller.parent.unknow_child_time + this_caller.this_time
            else
                -- 统计有名函数调用时间
                this_caller.parent.name_child_time = this_caller.parent.name_child_time + this_caller.this_time
            end
        end
    end
end

--[[
    获取缓存里的函数信息
    @info 函数调用信息debug.getinfo返回的数据
]]
function Profiler:get_func_info_by_cache( info )
    local func = info.func
    local ret = self.caller_cache[func]
    if ret == nil then
        ret = {}
        ret.func = func
        ret.count = 0 -- 调用次数
        ret.time = 0 -- 时间
        ret.unknow_child_time = 0 --没有名字的函数的调用时间
        ret.name_child_time = 0 -- 有名字的函数的调用时间
        ret.children = {}
        ret.children_time = {}
        ret.func_info = info
        self.caller_cache[func] = ret
    end
    return ret
end



local profiler = new_profiler("call")

profiler:start()


local info
local s = 1
local function ttt( ... )
    s = s + 1
    if s < 4 then
        return
    end
    -- for i=1,100000 do
    --     -- print(i)
    -- end
end

ttt()

-- debug.sethook(nil)


-- dump(info, "ccccccccccccc")



profiler:stop()


dump(profiler.caller_cache, "result")



