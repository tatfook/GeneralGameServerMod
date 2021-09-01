--[[
Title: Entity
Author(s):  wxa
Date: 2021-06-01
Desc: 定制 entity
use the lib:
------------------------------------------------------------
local Entity = NPL.load("Mod/GeneralGameServerMod/GI/Game/Entity/Entity.lua");
------------------------------------------------------------
]]


NPL.load("(gl)script/ide/mathlib.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityMovable.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMovable"), NPL.export());

function Entity:ctor()
    self.stepCount = 0;
end

function Entity:Init(opts)
    opts = opts or {};

    if (opts.name) then self:SetName(opts.name) end 
    if (opts.opacity) then self:SetOpacity(opts.opacity) end
    if (opts.item_id and opts.item_id ~= 0) then self.item_id = item_id end 
    
    self:SetBlockPos(opts.bx or 0, opts.by or 0, opts.bz or 0);
    self:SetMainAssetPath(opts.assetfile or "character/CC/02human/actor/actor.x");

    self:CreateInnerObject(self:GetMainAssetPath(), true, 0, 1, self:GetSkin());
	self:RefreshClientModel();
    self:Attach();

    return self;
end

function Entity:CheckEntityCollision()
    local entities = EntityManager.GetEntitiesByAABBExcept(self:GetCollisionAABB(), self);
    if (not entities or #entities == 0) then return end
    for _, entity in ipairs(entities) do
        self:CollideWithEntity(entity);
    end
end

function Entity:CollideWithEntity(entity)
end


function Entity:FrameMoveRidding()
end

function Entity:FrameMove()
end