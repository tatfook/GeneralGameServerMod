--[[
Title: ui
Author(s): wxa
Date: 2020/6/30
Desc: UI 入口文件, 实现组件化开发
use the lib:
-------------------------------------------------------
NPL.load("Mod/GeneralGameServerMod/App/ui/ui.lua");
local ui = commonlib.gettable("Mod.GeneralGameServerMod.App.ui.ui");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/mcml.lua");
NPL.load("Mod/GeneralGameServerMod/App/ui/Component.lua");
NPL.load("Mod/GeneralGameServerMod/App/ui/Slot.lua");
local mcml = commonlib.gettable("System.Windows.mcml");
local Component = commonlib.gettable("Mod.GeneralGameServerMod.App.ui.Component");
local Slot = commonlib.gettable("Mod.GeneralGameServerMod.App.ui.Slot");
local ui = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("Mod.GeneralGameServerMod.App.ui.ui"));

function ui:ctor()
    self.components = {};
end

-- 注册组件
function ui:Component(opts)
    if (type(opts) ~= "table") then return end
    -- 初始化参数
    local filename = opts.filename; 
    -- 定义组件函数
    local TagCtor = function(_self, xmlNode)
        return Component:new(xmlNode):Init({
            filename = filename,
        });
    end
    local GlobalComponentMap = Component.GetGlobalComponentMap();
    local Register = function (tagname, tagclass)
        GlobalComponentMap[tagname] = tagclass;
        mcml:RegisterPageElement(tagname, tagclass);
    end

    local TagClass = opts.tagclass or { new = TagCtor, createFromXmlNode = TagCtor}

    -- 注册组件
    local tagname = opts.tagname;
    if (type(tagname) == "string") then
        Register(tagname, TagClass);
        GlobalComponentMap[tagname] = TagClass;
    elseif (type(tagname) == "table") then
        for i, tag in ipairs(tagname) do
            Register(tag, TagClass);
        end
    else
        LOG:warn("无效组件:" .. tostring(tagname));
    end

    return TagClass;
end

function ui:StaticInit()
    self:Component({
        tagname = {"pe:component", "Component"},
        filename = "Mod/GeneralGameServerMod/App/ui/Component.html",
    });

    self:Component({
        tagname = "Slot",
        tagclass = Slot,
    });
end

ui:InitSingleton():StaticInit();