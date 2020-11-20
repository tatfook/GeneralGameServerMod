--[[
Title: G
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local G = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/G.lua");
-------------------------------------------------------
]]

local Storage = NPL.load("./Storage.lua", IsDevEnv);

local G = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

G:Property("Window");  -- 所属窗口
G:Property("G");       -- 真实G

local global_methods = {
    "CloseWindow",
}

function G.New(window, g)
    g = setmetatable(g or {}, {__index = _G});
    g.SessionStorage = Storage.SessionStorage;

    local _g = G:new():Init(window, g);
    for _, method in ipairs(global_methods) do
        g[method] = function(...) 
            return _g[method](_g, ...);
        end
    end
    return g;
end

function G:ctor()
end

function G:Init(window, g)
    self:SetWindow(window);
    self:SetG(g);
    return self;
end

function G:CloseWindow()
    self:GetWindow():CloseWindow();
end



