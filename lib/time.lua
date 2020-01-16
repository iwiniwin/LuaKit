--[[--时间操作
@module time
@author iwiniwin

Date   2020-01-16 13:27:14
Last Modified by   iwiniwin
Last Modified time 2020-01-16 13:44:56
]]
local time = {}

-- time.sleep = function ( num )
--     -- print("hhhh")
--     -- os.execute("sleep 1000")
--     io.popen("sleep 10000")
-- end
-- print(os.clock())

-- time.sleep(500000)
-- print("你好")

-- 单位是秒
require("socket")
time.sleep = function ( second )
    socket.select(nil, nil, second)
end

-- time.sleep = function ( second )
--     if second > 0 then
--         os.execute("ping -n " .. second + 1 .. " localhost > NUL")
--     end
-- end


-- time.sleep()

-- print("uuuuuu")


return time