--[[--ldoc desc
@module test
@author LensarZhang

Date   2018-05-02 18:49:40
Last Modified by   LensarZhang
Last Modified time 2018-05-02 19:25:39
]]


--[[
1. move动画
]]
-- local Anim = BYEngine.Animation
-- local move = Anim.prop('center_top', 5,-5,0.5)
-- local ac = Anim.spawn(move)
-- local anim = Anim.Animator()
-- anim:start(ac,function (v)
--    icon.center_top = v.center_top
-- end,kAnimLoop)  


--[[
2. lua沙盒
理解：lua沙盒就是通过改变上下文环境，使函数可以在不同的环境表中运行，访问得到限制，从而避免相互
影响。可以利用其构建一个安全的环境，用来执行一些未知的危险代码
]]


function test( ... )
	print("hello")
end

test()

-- 设置test在环境表e运行，此时test不能调用_G中的print
-- local e = {}
-- setfenv(test, {})
-- test()
-- setfenv(test, _G)
-- test()


-- 在e环境表对x赋值不会影响到f环境
local e = {print = print, setfenv = setfenv}
setfenv(1, e)
x = 3
print(x)
local f = {print = print, setfenv = setfenv}
setfenv(1, f)
print(x)