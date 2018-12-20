local AStar = {}

local tostring = function ( point )
    return point.x .. "*" .. point.y
end

function AStar:findPath( start, ends, size, blocks )
    self.size = size
    self.openList = {}
    self.closeList = {}
    self.ends = {x = ends[1], y = ends[2], g = 0, h = 0}
    self.start = {x = start[1], y = start[2], g = 0, h = 0}
    self.openList[tostring(start)] = self.start
    self:find()
end

function AStar:find( ... )

    local length = 1
    local openList, closeList = self.openList, self.closeList

    while(length > 0) do

        if openList[tostring(self.ends)] then
            -- 找到
        end

        local cur
        for k,p in pairs(openList) do
            cur = cur or p
            if p.g + p.h < cur.g + cur.h then
                cur = p
            end
        end

        openList[tostring(cur)] = nil 
        length = length - 1


        dump({x = cur.x, y = cur.y}, "xianzai------------------------------------")

        -- table.insert(closeList, cur)
        closeList[tostring(cur)] = cur

        local points = nearPoints(cur)

        for i,p in ipairs(points) do
            if openList[tostring(p)] then
                if cur.g and cur.g + 1 < v.g then
                    error(999)
                    -- 更新
                    v.g = cur.g + 1
                    v.parent = cur
                end
            else
                openList[tostring(p)] = p
            end            
        end
    end
end

function AStar:nearPoints( cur )

    local function usable( point )
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

    local points = {
        -- 左 右 上 下
        {x = x -1, y = y}, {x = x + 1, y = y}, {x = x, y = y -1}, {x = x, y = y + 1},
        -- 左上 左下 右上 右下
        {x = x - 1, y = y - 1}, {x = x - 1, y = y + 1}, {x = x + 1, y = y - 1}, {x = x + 1, y = y + 1},
    }

    local x, y = cur.x, cur.y

    for i = #points, 1, -1 do
        if usable(points[i], blocks, closeList, row, col) then
            local g, h = estimate(points[i], ends)
            points[i].g, points[i].h = g + (cur.g or 0), h
            points[i].parent = cur
        else
            table.remove(points, i)
        end
    end   
    return points 
end

local Point = {
    x = 0,
    y = 0,
}

local function estimate( point, ends )
    return 1, math.abs(ends.x - point.x) + math.abs(ends.y - point.y)
end

return AStar


AStar({x = 3, y = 3}, {x =7, y = 3}, 6, 8, {{x =5, y = 1}, {x = 5, y = 2}, {x = 5, y = 3}, {x = 5, y = 4}, {x = 5, y = 5}, {x =5, y = 6}})
