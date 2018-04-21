--[[--ldoc desc
@module MainSceneUI(1)
@author 莫玉成

Date   2017-12-28
Last Modified by   LensarZhang
Last Modified time 2018-04-03 11:29:09
]]


-- local layout = import(".layout");

local UI = require('byui.ui');
local MainSceneUI = class(UI.View);
local DockPackage = UI.import("scripts/app/modules/dock")


--local DockPackage = {}
--DockPackage.DockPanel = import("app.modules.dock.DockPanel")
--DockPackage.DockContent = import("app.modules.dock.DockContent")
MainSceneUI.className_ = "MainSceneUI"

local ModuleConfig = require("app.config.ModuleConfig");

function MainSceneUI:ctor(delegate)
    self.mDelegate = delegate;
    self.m_name = "MainSceneUI";
    -- self:initDockPanel();
    -- self:loadLayout();
    -- self:findView();
    -- self:autobindBehaviors();




    math.newrandomseed();

    local list = {};


    for i=1,1 do
        local v = new(UI.import("package/app/modules/edit").ViewClass);

        v.left = 100
                v.top = 100
        v:addTo(self);

        table.insert(list,v)
        
    end
    Clock.instance():schedule(function(dt)
           for k,v in pairs(list) do
                v.width = math.random(500)
                v.height = math.random(500)
            end 
    end)


    Clock.instance().calc_fps = true

    local fpsLabel = g_UICreator:createLabel({text='1', font_size=32,left=20,content_color = "red"});
    fpsLabel:addTo(self);
    -- self.background_color = "red";
    fpsLabel.position_type = YGPositionTypeAbsolute;
    -- self.bottom = 0;
    
    local fps = 0;
    local time = 0;
    self.mHandler = Clock.instance():schedule(function(dt)
        fps = fps + 1
        time = time + dt
        if time >=1 then
            fpsLabel.text = "fps: " .. fps;
            time = time - 1;
            -- dump(fps,"fps")
            fps = 0;
        end
    end)


end


function MainSceneUI:dtor()
    self.dockMainView = nil
    self.mainDockLayout = nil
    self.mDelegate = nil;
    self:unBindCtr();
end

function MainSceneUI:autobindBehaviors()
    if self.className_ and BehaviorConfig[self.className_] then
        for k,v in pairs(BehaviorConfig[self.className_]) do
            self:bindBehavior(v);
        end
    end
end

---加载布局文件
function MainSceneUI:loadLayout()

    self.flex = 1
    self.width = "100%"
    self.height = "100%"
    self.background_color = "#515151";
    self.position_type = YGPositionTypeAbsolute


    -- local bg = g_UICreator:createImage({unit = "BoyaaIDE/PanelGrid2048.png",
    --     position_type = YGPositionTypeAbsolute,
    --     width = "100%",height = "100%"});
    -- -- local bg = UI.View{
    -- --        unit = {
    -- --               file = "BoyaaIDE/PanelGrid.png",
    -- --               slice9 = 10,
    -- --        },
    -- --        set_unit_slice9 = true,
    -- --        slice9 = 10,
    -- --        width = "100%",height = "100%",
    -- --    }
    -- bg:addTo(self);


    self:loadModules();

    self:initSceneDelegate();
    -- g_Director:getRunningScene():getMergeView()
    g_EventDispatcher:dispatch(g_Event.START_PROJECT,{});

end

function MainSceneUI:onSizeChange(data)
    --todo同步修改窗口大小比例
end

function MainSceneUI:initDockPanel()
    self.dockPanel = new(DockPackage.DockPanel)
    self.dockPanel:addTo(self)
    --初始化大小
    local width = UI.main_window.window.size.x
    local height = UI.main_window.window.size.y
    local top = ModuleConfig.MenuView.props.height
    self.dockPanel:setPosAndSize(0, top, width, height - top)
end

---创建DockContent模块
function MainSceneUI:createDockContent(param,name)
    local moduleview = self:getModule(name)
    local dockContent = nil
    if moduleview == nil then
        moduleview = self:createModule(param, name)
        self:addModule(moduleview)
        dockContent = new(DockPackage.DockContent, moduleview, param.dockData.name)
        dockContent:update_layout()
        if param.dockData.isShow ~= false then
            dockContent:Show(self.dockPanel, param.dockData)
        end
    else
        dockContent = moduleview.parent
        dockContent:Show(self.dockPanel, param.dockData)
    end
    
    return moduleview
end

--根据key加载modules
function MainSceneUI:loadModulesByKey(key)
    for k,v in pairs(ModuleConfig) do
        if key == k then
            if not v.dockData then
                local obj = self:createModule(v,k) 
                return self:addModule(obj)
            else
                return self:createDockContent(v,k)
            end
            
        end
    end
end

function MainSceneUI:closeModulesByKey(key)
    local moduleview = self:getModule(key)
    if moduleview ~= nil then
        local dockContent = moduleview.parent
        dockContent.Pane:RemoveContent(dockContent)
    end
end

function MainSceneUI:initSceneDelegate()
    -- body
    self.on_touch = function(v,t,b)
        local data = 
        {
            obj = v,
            touch = t,
            cancel = b,
        }
        g_EventDispatcher:dispatch(g_Event.TOUCH_RUNNING_SCENE,data);
    end
    self.on_mouse_scroll = function(v,offsetx,offsety)
        local data = 
        {
            obj = v,
            x = offsetx,
            y = offsety,
        }
        g_EventDispatcher:dispatch(g_Event.MOUSE_SCROLL_MOVE,data);
    end
end

function MainSceneUI:loadModules()
    self.moduleList = {};
    local list = {}
    for k,v in pairs(ModuleConfig) do
        local data = {
            k = k,
            v = v,
        }
        table.insert(list, data);
    end
    table.sort(list, function(a, b)
        if a.v.initzorder == nil and b.v.initzorder ~= nil then
            return true;
        elseif a.v.initzorder ~= nil and b.v.initzorder ~= nil then
            if a.v.initzorder < b.v.initzorder then
                return true
            end
        end
        return false
    end)

    for k,data in pairs(list) do
        if not data.v.dockData then
            local obj = self:createModule(data.v, data.k)
            self:addModule(obj)
        else
            self:createDockContent(data.v, data.k)
        end
    end
end


---创建模块
function MainSceneUI:createModule(param,name)
    param = checktable(param);
    local key = name;
    local ViewClass = nil
    if param.ViewClass then
        ViewClass = param.ViewClass
    else
        local file  = param.file;
        assert(file);
        ViewClass = g_reload(file);
    end
    local viewObj = new(ViewClass,param.param);
    viewObj.visible = (param.visible == nil and true or param.visible);
    viewObj.tag_ = {param = param,name = name};
    if param.props then
        viewObj:props(param.props)
    end
    ---绑定组件
    if param.behaviors then
        for i,v in ipairs(param.behaviors) do
            viewObj:bindBehavior(v);
        end
    end

    return viewObj
end

function MainSceneUI:addModule(viewObj)
    local tag_ = checktable(viewObj.tag_);
    local name = tag_.name;
    local key =  name;
    if self.moduleList[key] then
        error("已经存在," .. key,name)
        return;
    end
    viewObj:addTo(self);
    self.moduleList[key] = viewObj;

    self.mDelegate["get" .. name] = function()
        return self.moduleList[name]
    end

end

function MainSceneUI:getModule(name)
    return self.moduleList[name]
end

function MainSceneUI:removeModule(viewObj)
    local tag_ = checktable(viewObj.tag_);
    local name = tag_.name;
    local key =  name;
    local obj = self.moduleList[key]
    if obj then
        obj:removeSelf();
        self.moduleList[key] = nil;
    end


end

---查找子控件
function MainSceneUI:findView()
--self.mIcon = self:getChildByName2("xxxx");
end

---刷新界面
function MainSceneUI:updateView(data)
    data = checktable(data);
    -- if data.xxx and self.xxx then
    --  --todo
    -- end
    if data.hide == true then
        self:setVisible(false)
    else
        self:setVisible(true);
    end
end



return MainSceneUI;

