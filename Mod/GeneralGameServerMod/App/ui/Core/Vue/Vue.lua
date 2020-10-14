--[[
Title: Vue
Author(s): wxa
Date: 2020/6/30
Desc: 组件基类
use the lib:
-------------------------------------------------------
local Component = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Vue/Component.lua");
-------------------------------------------------------
]]

local Window = NPL.load("../Window/Window.lua", IsDevEnv);
local ElementManager = NPL.load("../Window/ElementManager.lua", IsDevEnv);
local Component = NPL.load("./Component.lua", IsDevEnv);
local Helper = NPL.load("./Helper.lua", IsDevEnv);

ElementManager:RegisterByTagName("Component", Component);

local Vue = commonlib.inherit(Window, NPL.export());

function Vue:LoadXmlNodeByUrl(url)
    return {
        name = "html",
        attr = {
            style = "width: 100%; height:100%;",
        }, 
        {
            name = "component",
            attr = {
                src = url or "%ui%/Core/Window/Window.html",
            }
        }
    }
end

function Vue.Register(tagname, tagclass)
    ElementManager:RegisterByTagName(tagname, Component.Extend(tagclass))
end

-- 静态初始化
local function StaticInit()
    Vue.Register("WindowTitleBar", "%ui%/Core/Components/WindowTitleBar.html");
end

StaticInit();

if (_G.Vue) then _G.Vue:CloseWindow() end
_G.Vue = Vue:new();
Vue.Test = _G.Vue;