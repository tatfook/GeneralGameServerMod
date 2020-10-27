--[[
Author: wxa
Date: 2020-10-26
Desc: 新手引导 Level_0 
-----------------------------------------------
local Level_0 = NPL.load("Mod/GeneralGameServerMod/Level/Level_0.lua");
local Level_0 = Level_0:new():Init(tutorial);
-----------------------------------------------
]]

local Level = NPL.load("./Level.lua", IsDevEnv);
local Level_0 = commonlib.inherit(Level, NPL.export());

Level_0:Property("Tutorial");

function Level_0:ctor()
end

function Level_0:Init(tutorial)
    Level_0._super.Init(self, tutorial);

    self:InitEnv();
    self:InitEvent();

    return self;
end

function Level_0:InitEnv()
    local CodeEnv = self:GetCodeEnv();
    CodeEnv.becomeAgent("@p");  -- 成为当前玩家化身, 方便移动
end

function Level_0:InitEvent()
    local CodeEnv = self:GetCodeEnv();
    local CodeBlock = self:GetCodeBlock();

    CodeEnv.registerKeyPressedEvent("w", function(msg)
        log("w is pressed");
    end);
    CodeEnv.registerKeyPressedEvent("s", function(msg)
        log("s is pressed");
    end);
    CodeEnv.registerKeyPressedEvent("a", function(msg)
        log("a is pressed");
    end);
    CodeEnv.registerKeyPressedEvent("d", function(msg)
        log("d is pressed");
    end);
    CodeEnv.registerKeyPressedEvent("mouse_buttons", function(event)
        log(event:button());
        if(event:buttons() == 1 and event.isDoubleClick) then
        end
    end);

    -- 这个需要自己补事件触发
    CodeBlock:RegisterTextEvent("mouseReleaseEvent", function(event)
        log("mouseReleaseEvent")
    end);
end
