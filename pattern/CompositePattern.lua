--[[--
组合模式
@module CompositePattern
@author iwiniwin

Date   2019-11-15 19:20:39
Last Modified by   iwiniwin
Last Modified time 2020-01-16 13:39:53
]]
package.path = package.path .. ";..\\?.lua;"
require("_load")

--[[
    适配器模式
    定义：
        将一个类的接口，转换成客户期望的另一个接口。适配器让原本接口不相容的类可以合作无间
    优点：
        组合以单一责任设计原则换取透明性。什么是透明性？通过让组件的接口同时包含一些管理子节点和叶子节点的操作，
        客户就可以将组合和叶子节点一视同仁。也就是说，一个元素究竟是组合还是叶子节点，对客户是透明的
]]

-- 利用组合模式来设计菜单

-- 菜单组件提供了一组接口，让菜单和菜单项共同使用
local MenuComponent = class();
function MenuComponent:getName( ... )
end
function MenuComponent:getPrice( ... )
end
function MenuComponent:add( component )
end
function MenuComponent:remove( component )
end
function MenuComponent:getChild( index )
end
function MenuComponent:print(  )
end


-- 菜单（组合菜单）。覆盖一些菜单组件对它有用的方法。此组合类可以持有菜单项和其它菜单
local Menu = class(MenuComponent);
function Menu:ctor( name )
    self.name = name
    self.menuComponents = {}  -- 菜单下可以有更多组件
end
function Menu:getName( ... )
end
function Menu:add( component )
    table.insert(self.menuComponents, component)
end
function Menu:remove( component )
    table.remove(self.menuComponents, component)
end
function Menu:getChild( index )
    return self.menuComponents[index]
end
function Menu:print(  )
    dump("menu : name is " .. self.name)
    for i,v in ipairs(self.menuComponents) do
        v:print();
    end
end

-- 菜单项。也覆盖一些对它有意义的方法。没有意义的就置之不理。因为菜单项已经是叶子节点，所以它的下面不能有任何组件
local MenuItem = class(MenuComponent);
function MenuItem:ctor( name, price )
    self.name = name
    self.price = price
end
function MenuItem:getName( ... )
end
function MenuItem:getPrice( ... )
end
function MenuItem:print( ... )
    dump("menu item : name is " .. self.name .. ", price is " .. self.price)
end

-------------- 测试 -------------- 

local pancakeHouseMenu = new(Menu, "PANCAKE HOUSE MENU");  -- 煎饼屋菜单
local dinerMenu = new(Menu, "DINER MENU");  -- 餐厅菜单
local cafeMenu = new(Menu, "CAFE MENU");  -- 咖啡菜单

local allMenus = new(Menu, "ALL MENUS")
allMenus:add(pancakeHouseMenu);
allMenus:add(dinerMenu)
allMenus:add(cafeMenu)

dinerMenu:add(new(MenuItem, "Pasta", 3.89));  -- 加入菜单项，面团

local dessertMenu = new(Menu, "DESSERT MENU");  -- 甜点菜单
dessertMenu:add(new(MenuItem, "Apple Pie", 1.59));  -- 加入菜单项

dinerMenu:add(dessertMenu);  -- 加入菜单，甜点菜单（甜点菜单属于餐厅菜单的子菜单）

allMenus:print()

--[[
menu : name is ALL MENUS
menu : name is PANCAKE HOUSE MENU"
menu : name is DINER MENU"
menu item : name is Pasta, price is 3.89"
menu : name is DESSERT MENU"
menu item : name is Apple Pie, price is 1.59"
menu : name is CAFE MENU"
]]