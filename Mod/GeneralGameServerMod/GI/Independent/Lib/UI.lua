--[[
Title: UI
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local UI = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/UI.lua");
------------------------------------------------------------
]]

local UI = inherit(nil, module("UI"));

function UI.ShowWindow(G, params)
    G = G or {};

    return ShowWindow(G, params);
end

function UI.ShowEditWindow(text, callback)
    ShowWindow({
        text = text or "",
        OnClose = function(G)
            __call__(callback, G.value);
        end
    }, {
        url = "%gi%/Independent/UI/EditWindow.html",
    });
end



