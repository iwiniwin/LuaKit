require("_load")

local AStar = {}
local tostring = function ( point )
    return point.x .. "*" .. point.y
end

function AStar:findPath( start, ends, size, blocks, params )
    self.size = size
    self.openList = {}
    self.closeList = {}
    self.blocks = {}
    for i,p in ipairs(blocks) do
        p = {x = p[1], y = p[2]}
        self.blocks[tostring(p)] = p
    end
    self.ends = {x = ends[1], y = ends[2], g = 0, h = 0}
    self.start = {x = start[1], y = start[2], g = 0, h = 0}

    self.openList[tostring(self.start)] = self.start
    params = params or {}
    self.straightWeight = params.straightWeight or 1
    self.obliqueEnable = params.obliqueEnable
    self.obliqueWeight = params.obliqueWeight or 1.4
    self.cornerEnable = params.cornerEnable or  params.cornerEnable == nil
    return self:find()
end 

function AStar:find( ... )

    local length = 1
    local openList, closeList = self.openList, self.closeList


    while(length > 0) do
        if openList[tostring(self.ends)] then
            local parent = openList[tostring(self.ends)]
            local list = {}
            while parent do
                table.insert(list, 1, {parent.x, parent.y})
                parent = parent.parent
            end
            return list
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



        local points = self:nearPoints(cur)

        for i,p in ipairs(points) do

            dump({x = p.x, y = p.y}, "open_____")
            if openList[tostring(p)] then
                -- dump({x = p.x, y = p.y, g1 = self:estimate(cur, p), m1 = cur.g, g = p.g}, "again_____")
                -- local g = cur.g + self:estimate(cur, p)
                if p.g < openList[tostring(p)].g then
                    -- error(999)
                    -- 更新
                    openList[tostring(p)] = p
                end
            else
                openList[tostring(p)] = p
                length = length + 1
            end            
        end
    end

    -- dump(x, "fffffffffffff")
end

function AStar:nearPoints( cur )

    local function usable( point )
        local x, y = point.x, point.y
        if x >= 1 and x <= self.size[1] and y >= 1 and y <= self.size[2] then
            -- 边界内
            local key = tostring(point)
            if self.blocks[key] or self.closeList[key] then
                return false
            end
            if self.obliqueEnable and not self.cornerEnable then
                if self.blocks[tostring({x = cur.x, y = y})] or self.blocks[tostring({x = x, y = cur.y})] then
                    return false
                end
            end
            return true
        end
    end

    local x, y = cur.x, cur.y
    local points = {
        {x = x -1, y = y}, {x = x + 1, y = y}, {x = x, y = y -1}, {x = x, y = y + 1},
        {x = x - 1, y = y - 1}, {x = x - 1, y = y + 1}, {x = x + 1, y = y - 1}, {x = x + 1, y = y + 1}, 
    }

    for i = #points, 1, -1 do
        if (self.obliqueEnable or (not self.obliqueEnable and i <= 4)) and usable(points[i]) then
        -- if usable(points[i]) then
            local g, h = self:estimate(cur, points[i])
            points[i].g, points[i].h = g + cur.g, h


            dump(points[i], "uuuu")
            points[i].parent = cur
        else
            table.remove(points, i)
        end
    end   
    return points 
end

function AStar:estimate( cur, point )
    local g = (math.abs(cur.x - point.x) + math.abs(cur.y - point.y) > 1) and self.obliqueWeight or self.straightWeight 
    local h = (math.abs(self.ends.x - point.x) + math.abs(self.ends.y - point.y)) * self.straightWeight
    return g, h
    -- return oblique and self.obliqueWeight or self.straightWeight, math.abs(self.ends.x - point.x) + math.abs(self.ends.y - point.y)
end

-- local tostring = _G["tostring"]
-- math.randomseed(tostring(os.time()):reverse():sub(1, 6))

-- local blocks = {}
-- while #blocks < 5000 do
--     local x = math.random(128)
--     local y = math.random(128)
--     -- dump(x, y)
--     if not blocks[x .. "*" ..  y] then
--         table.insert(blocks, {x, y})
--         blocks[x .. "*" .. y] = true
--     end
-- end




-- local start 
-- local x, y = math.random(128), math.random(128)
-- while not start do
--     if not blocks[x .. "*" ..  y] then
--         start = {x, y}
--         blocks[x .. "*" .. y] = true
--     end
--     x , y =  math.random(128), math.random(128)
-- end



-- local ends 
-- local x, y = math.random(128), math.random(128)
-- while not ends do
--     if not blocks[x .. "*" ..  y] then
--         ends = {x, y}
--         blocks[x .. "*" .. y] = true
--     end
--     x , y =  math.random(128), math.random(128)
-- end



local t = os.clock()
-- for i = 1, 10000 do
-- local list = AStar:findPath(start, ends, {128, 128}, blocks)
-- local a = AStar:findPath({3, 3}, {7, 3}, {8, 6}, {{5, 1}, {5, 2}, {5, 3}, {5, 4}, {5, 5}, {5, 6}})
local a = AStar:findPath({3, 3}, {7, 3}, {8, 6}, {{5, 2}, {5, 3}, {5, 4}}, {obliqueEnable = true, cornerEnable = false})
-- local a = AStar:findPath({3, 3}, {7, 3}, {8, 6}, {{5, 2}, {5, 3}, {5, 4}})
-- end
dump(os.clock() - t)




dump(a, "sssssssssssss")

-- dump(start, "开始")

-- dump(ends, "终点")


return AStar




-- AStar({x = 3, y = 3}, {x =7, y = 3}, 6, 8, {{x =5, y = 1}, {x = 5, y = 2}, {x = 5, y = 3}, {x = 5, y = 4}, {x = 5, y = 5}, {x =5, y = 6}})
