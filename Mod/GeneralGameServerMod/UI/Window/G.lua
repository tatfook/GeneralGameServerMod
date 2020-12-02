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


function G.New(window, g)
    g = setmetatable(g or {}, {__index = _G});
    g.SessionStorage = Storage.SessionStorage;

    local _g = G:new():Init(window, g);
    for method in pairs(G) do
        if (type(rawget(G, method)) == "function" and method ~= "ctor" and method ~= "Init") then
            g[method] = function(...) 
                return _g[method](_g, ...);
            end
        end
    end

    g.Log = GGS.INFO;

    return g;
end

function G:ctor()
    self.timers = {};
end

function G:Init(window, g)
    self:SetWindow(window);
    self:SetG(g);
    return self;
end

function G:ToString(obj)
    return GGS.Debug.ToString(obj);
end

function G:CloseWindow()
    for timer in pairs(self.timers) do timer:Change() end

    self:GetWindow():CloseWindow();
end

function G:GetTime()
    return ParaGlobal.timeGetTime()
end

function G:SetTimeout(func, timeoutMS)
    local timer = commonlib.TimerManager.SetTimeout(func, timeoutMS);
    self.timers[timer] = timer;
    return timer;
end

function G:ClearTimeout(timer)
    if (not timer) then return end
    return commonlib.TimerManager.ClearTimeout(timer);
end

function G:SetInterval(func, intervalMS)
    local timer = commonlib.TimerManager.SetInterval(func, intervalMS);
    self.timers[timer] = timer;
    return timer;
end

function G:ClearInterval(timer)
    if (not timer) then return end
    return commonlib.TimerManager.ClearInterval(timer);
end