--[[
Title: App
Author(s): wxa
Date: 2020/6/30
Desc: 组件根元素
use the lib:
-------------------------------------------------------
local Slot = NPL.load("Mod/GeneralGameServerMod/App/ui/Component.lua");
-------------------------------------------------------
]]
local Component = NPL.load("./Component.lua");
local App = commonlib.inherit(Component, NPL.export());

-- 通过xml节点创建页面元素
function App:createFromXmlNode(o)
    o.filename = o.attr and o.attr.filename;
    return self:new(o);
end