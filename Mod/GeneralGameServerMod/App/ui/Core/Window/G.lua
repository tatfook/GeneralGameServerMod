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

local G = NPL.export();

function G:SetWindow(window)
    self.window = window;
end

function G:GetWindow()
    return self.window;
end

function G:Init(window)
    self:SetWindow(window);
    return self;
end

setmetatable(G, {
    __index = _G,
    __call = function(G, window, g)
        local self = setmetatable(g or {}, {__index = G}):Init(window);

        self.CloseWindow = function()
            self:GetWindow():CloseWindow();
        end

        return self;
    end
});


-- function G.CloseWindow()
--     GetWindow():CloseWindow();
-- end

-- setmetatable(G, {
--     __index = _G,
--     __call = function(G, window, g)
--         g = setmetatable(g or {}, {__index = G});
--         g.GetWindow = function() 
--             return window;
--         end
--         return g;
--     end
-- });