--[[
Title: EntityCustom
Author(s):  wxa
Date: 2021-06-01
Desc: 定制 entity
use the lib:
------------------------------------------------------------
local EntityCustom = NPL.load("Mod/GeneralGameServerMod/GI/Game/Entity/EntityCustom.lua");
------------------------------------------------------------
]]
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld")
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB")
local vector3d = commonlib.gettable("mathlib.vector3d")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager")

local EntityCustom = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMob"), NPL.export())

local math_abs = math.abs
local math_random = math.random
local math_floor = math.floor
local NID = 0

-- whether this entity can be synchronized on the network by EntityTrackerEntry.
EntityCustom.isServerEntity = false
-- class name
EntityCustom.class_name = "EntityCustom"
EntityCustom.entityCollisionReduction = 1.0

-- 事件类型
EntityCustom.Listener = {
    OnClick = "onclick",
}

-- register class
EntityManager.RegisterEntityClass(EntityCustom.class_name, Entity)

EntityCustom:Property("Listener"); -- 事件监听器
EntityCustom:Property("EnablePhysics", false, "IsEnablePhysics"); -- 事件监听器

local function GetNextNID()
    NID = NID + 1
    return NID
end

function EntityCustom:init()
    self.name = Entity.class_name .. tostring(self:GetNextNID())
    self:SetListener(GI.Listener:new():Init(self))
    local x, y, z = self:GetPosition()
    local model = ParaScene.CreateObject("BMaxObject", self.name, x, y, z)
    model:SetField("assetfile", self.mModel)
    if self.mReplaceTextures then
        local temp = self.mReplaceTextures
        repeat
            local split_begin = string.find(temp, ":")
            local split_end = string.find(temp, ";")
            if not split_end then
                break
            end
            local tex_index = string.sub(temp, 1, split_begin - 1)
            tex_index = tonumber(tex_index)
            local tex_name = string.sub(temp, split_begin + 1, split_end - 1)
            model:SetReplaceableTexture(tex_index, ParaAsset.LoadTexture("", tex_name, 1))
            temp = string.sub(temp, split_end + 1)
        until true
    end
    if (self.scale) then
        model:SetScaling(self.scale)
    end
    if (self.facing) then
        model:SetFacing(self.facing)
    end
    -- MESH_USE_LIGHT = 0x1<<7: use block ambient and diffuse lighting for this model.
    model:SetAttribute(0x80, true)
    model:SetField("RenderDistance", 100)
    model:SetField("EnablePhysics", self:IsEnablePhysics());
    self:SetInnerObject(model)
    ParaScene.Attach(model)
    self:UpdateBlockContainer()
    self:EnablePhysics(self:IsEnablePhysics(), true)
    self.entity_id = nil
    EntityManager.AddObject(self)
    return self
end

function EntityCustom:OnClick(x, y, z, mouse_button)
    mouse_button = mouse_button or "left";
    self:GetListener():Notify(EntityCustom.Listener.OnClick, x, y, z, mouse_button);
    return true
end

function EntityCustom:SetBlockPos(x, y, z)
    EntityCustom._super.SetBlockPos(self, x, y, z)
    self:EnablePhysics(self:IsEnablePhysics(), true);
end

function EntityCustom:SetPosition(x, y, z)
    EntityCustom._super.SetPosition(self, x, y, z)
    self:EnablePhysics(self:IsEnablePhysics(), true);
end

function EntityCustom:CheckCollision(vel)
    local e = 0.01
    local aabb = self:GetCollisionAABB()
    local ext = aabb:clone()
    local min = ext:GetMin()
    local max = ext:GetMax()
    ext:Extend(min[1] + vel[1], min[2] + vel[2], min[3] + vel[3])
    ext:Extend(max[1] + vel[1], max[2] + vel[2], max[3] + vel[3])

    local listCollisions = PhysicsWorld:GetCollidingBoundingBoxes(ext, self)

    local facing = self:GetFacing()
    local dx, dy, dz
    dx = vel[1]
    dy = vel[2]
    dz = vel[3]
    local offsetX, offsetY, offsetZ = dx, dy, dz

    for i = 1, listCollisions:size() do
        offsetY = listCollisions:get(i):CalculateYOffset(aabb, offsetY, e)
    end

    for i = 1, listCollisions:size() do
        offsetX = listCollisions:get(i):CalculateXOffset(aabb, offsetX, e)
    end
    for i = 1, listCollisions:size() do
        offsetZ = listCollisions:get(i):CalculateZOffset(aabb, offsetZ, e)
    end

    -- if offsetY ~= dy then
    --   offsetX = dx;
    --   offsetZ = dz;
    -- elseif offsetX ~= dx then
    --   offsetY = dy;
    --   offsetZ = dz;
    -- elseif offsetZ ~= dz then
    --   offsetX = dx;
    --   offsetY = dy;
    -- end

    return offsetX, offsetY, offsetZ
    -- local newFacing = Direction.GetFacingFromOffset(dx, 0, dz);
    -- self:SetFacing(newFacing);
end

function EntityCustom:setCenterOffset(x, y, z)
    self.centerOffset = {x, y, z}
end

function EntityCustom:GetCollisionAABB()
    self.centerOffset = self.centerOffset or {0, 0, 0}
    if (self.aabb) then
        local x, y, z = self:GetPosition()
        y = y + self.centerOffset[2]
        self.aabb:SetBottomPosition(x, y, z)
    else
        self.aabb = ShapeAABB:new()
        local x, y, z = self:GetPosition()
        local radius = self:GetPhysicsRadius()
        local half_height = self:GetPhysicsHeight() * 0.5
        self.aabb:SetCenterExtend(
            vector3d:new({x, y + half_height + self.centerOffset[2], z}),
            vector3d:new({radius, half_height, radius})
        )
    end
    return self.aabb
end
