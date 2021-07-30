--[[
Title: Entity
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local Entity = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Lib/Entity.lua");
------------------------------------------------------------
]]

local Entity = inherit(__Entity__, module("Entity"));

function Entity:Init(opts)
    opts = opts or {};

    if (opts.assetfile and string.match(opts.assetfile, "^@")) then
        opts.assetfile = string.gsub(opts.assetfile, "@", GetWorldDirectory());
        opts.assetfile = ToCanonicalFilePath(opts.assetfile);
    end

    Entity._super.Init(self, opts);
    __AddEntity__(self);
    return self;
end

function Entity:SetAnimId(animId)
    self:GetInnerObject():SetField("AnimID", animId or 0);
end

function Entity:Turn(degree)
    self:SetFacingDelta(degree * math.pi / 180);
end

function Entity:TurnTo(degree)
    self:SetFacing(mathlib.ToStandardAngle(degree * math.pi / 180));
end

function CreateEntity(opts)
    return Entity:new():Init(opts);
end
