--[[
Title: Vue
Author(s): wxa
Date: 2020/6/30
Desc: 组件基类
use the lib:
-------------------------------------------------------
local Vue = NPL.load("Mod/GeneralGameServerMod/UI/Vue/Vue.lua");
-------------------------------------------------------
]]

local Window = NPL.load("../Window/Window.lua", IsDevEnv);
local ElementManager = NPL.load("../Window/ElementManager.lua");
local Helper = NPL.load("./Helper.lua", IsDevEnv);
local Scope = NPL.load("./Scope.lua", IsDevEnv);
local ComponentScope = NPL.load("./ComponentScope.lua", IsDevEnv);
local Table = NPL.load("./Table.lua", IsDevEnv);
local Compile = NPL.load("./Compile.lua", IsDevEnv);
local Component = NPL.load("./Component.lua", IsDevEnv);
local Slot = NPL.load("./Slot.lua", IsDevEnv);

ElementManager:RegisterByTagName("Component", Component);
ElementManager:RegisterByTagName("Slot", Slot);

local Vue = commonlib.inherit(Window, NPL.export());

function Vue:ctor()
    self.pages = {};
end

function Vue:CloseWindow()
    Vue._super.CloseWindow(self);
    for _, page in pairs(self.pages) do
        page:CloseWindow();
    end
end

function Vue:LoadXmlNodeByUrl(url)
    return {
        name = "html",
        attr = {
            style = "width: 100%; height:100%; display: flex; justify-content: center; align-items: center;",
            -- id = "debug"
        }, 
        {
            name = "component",
            attr = {
                src = url,
            }
        }
    }
end

function Vue:LoadXmlNodeByTemplate(template)
    return {
        name = "html",
        attr = {
            style = "width: 100%; height:100%; display: flex; justify-content: center; align-items: center;",
        }, 
        {
            name = "component",
            template = template,
            attr = {
            }
        }
    }
end

-- 扩展全局方法
function Vue:ExtendG(G)
    G.ShowWindow = function(G, params)
        params = params or {};
        if (not params.url) then return end

        local page = self.pages[params.url] or Vue:new();
        self.pages[params.url] = page;
        if (page:GetNativeWindow()) then return page end

        params.G = G;
        
        return page:Show(params);
    end

    G.GetGlobalScope = function()
        if (not rawget(G, "GlobalScope")) then
            G.GlobalScope = Scope:__new__();
            G.GlobalScope:__set_metatable_index__(G);
        end
        return G.GlobalScope;
    end

    G.table = Table;  -- 替换全局table以便支持scope特性
end

function Vue:NewG(g)
    local G = Vue._super.NewG(self, g);

    self:ExtendG(G);

    return G;
end

function Vue.Register(tagname, tagclass)
    ElementManager:RegisterByTagName(tagname, Component.Extend(tagclass))
end

function Vue.SetPathAlias(alias, path)
    Helper.SetPathAlias(alias, path);
end

-- 静态初始化
local function StaticInit()
    Vue.Register("WindowTitleBar", "%vue%/Components/WindowTitleBar.html");
end


StaticInit();
