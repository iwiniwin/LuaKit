require("_load")


-- dump("zzzzzzzzzzz")

-- require("pattern.TemplatePattern")

-- https://blog.csdn.net/u012723995/article/details/40455357
-- 模块加载 性能分析 面向对象 组件 事件系统 数据观察追踪 回退系统 MVC

function class(super, autoConstructSuper)
  local classType = {};
  classType.autoConstructSuper = autoConstructSuper or (autoConstructSuper == nil);

  if super then
    classType.super = super;
    local mt = getmetatable(super);
    setmetatable(classType, { __index = super; __newindex = mt and mt.__newindex;});
  else
    classType.setDelegate = function(self,delegate)
      self.m_delegate = delegate;
    end
  end

  return classType;
end



local Point = {
    x = 0,
    y = 0,
}

local function estimate( point, ends )
    return 1, math.abs(ends.x - point.x) + math.abs(ends.y - point.y)
end

local function usablePoint( point, blocks, closeList, row, col )
    local x, y = point.x, point.y
    if x >= 1 and x <= col and y >= 1 and y <= row then
        -- 边界内
        for i,p in ipairs(blocks) do
            if p.x == x and p.y == y then
                return
            end
        end
        for i,p in ipairs(closeList) do
            if p.x == x and p.y == y then
                return
            end
        end
        return true
    end
end

local function nearPoints( cur, ends, blocks, closeList, row, col )
    local x, y = cur.x, cur.y
    local points = {
        {x = x -1, y = y}, {x = x + 1, y = y}, {x = x, y = y -1}, {x = x, y = y + 1}}
    for i = #points, 1, -1 do
        if usablePoint(points[i], blocks, closeList, row, col) then
            local g, h = estimate(points[i], ends)
            points[i].g, points[i].h = g + (cur.g or 0), h
            points[i].parent = cur
        else
            table.remove(points, i)
        end
    end   
    return points 
end

local x = 0

local function AStar( start, ends, row, col, blocks )
    local openList = {}
    local closeList = {}

    table.insert(openList, start)

    while(#openList > 0) do

        local index = 1
        for i,p in ipairs(openList) do
            if p.x == ends.x and p.y == ends.y then
                -- 找到

                while(p.parent) do
                    print(p.x , p.y)
                    p = p.parent
                end
                print(p.x, p.y)
                return
                print("找到")
            end
            if i > 1 and p.g + p.h < openList[index].g + openList[index].h then
                index = i
            end
        end
        

        local cur = table.remove(openList, index)


        dump({x = cur.x, y = cur.y}, "xianzai------------------------------------")

        table.insert(closeList, cur)

        local points = nearPoints(cur, ends, blocks, closeList, row, col)



        


        for i,v in ipairs(points) do
            local flag = false
            for i,p in ipairs(openList) do
                if p.x == v.x and p.y == v.y then
                    flag = true
                end
            end
            if flag then

                if cur.g and cur.g + 1 < v.g then
                    error(999)
                    -- 更新
                    v.g = cur.g + 1
                    v.parent = cur
                end
            else
                table.insert(openList, v)
            end
            
        end


    end

    dump("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
end


-- AStar({x = 3, y = 3}, {x =7, y = 3}, 6, 8, {{x =5, y = 1}, {x = 5, y = 2}, {x = 5, y = 3}, {x = 5, y = 4}, {x = 5, y = 5}, {x =5, y = 6}})

local a = {
    -- [3] = "lll"
}

local b = {
    length = 0
}

setmetatable(a, {
    __newindex = function ( t, k, v )
        if b[k] ~= nil and v == nil then
            b.length = b.length -1
        elseif b[k] == nil and v ~= nil then
            b.length = b.length + 1
        end
        b[k] = v
    end,
    __index = b
})


a[3] = 5


a[3] = 4

-- a[3] = nil

a["ssdf"] = 'uuu'

a[3] = nil
dump(a, "ffffffff")


dump(a.length)
