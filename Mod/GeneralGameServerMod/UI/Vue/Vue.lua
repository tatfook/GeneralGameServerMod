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
local ElementManager = NPL.load("../Window/ElementManager.lua");
local Component = NPL.load("./Component.lua", IsDevEnv);
local Slot = NPL.load("./Slot.lua", IsDevEnv);
local Helper = NPL.load("./Helper.lua", IsDevEnv);

ElementManager:RegisterByTagName("Component", Component);
ElementManager:RegisterByTagName("Slot", Slot);

local Vue = commonlib.inherit(Window, NPL.export());

function Vue:LoadXmlNodeByUrl(url)
    return {
        name = "html",
        attr = {
            style = "width: 100%; height:100%;",
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
            style = "width: 100%; height:100%;",
        }, 
        {
            name = "component",
            template = template,
            attr = {
            }
        }
    }
end

function Vue:NewG(g)
    local G = Vue._super.NewG(self, g);

    -- 扩展全局方法
    G.ShowWindow = function(params)
        return Vue:new():Show(params);
    end

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
