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

local __all_block_index_entity__ = {};

Entity:Property("Name", "GI_Entity");
Entity:Property("DestroyBeCollided", false, "IsDestroyBeCollided");   -- 被碰撞销毁
Entity:Property("Biped", false, "IsBiped");                           -- 是否是两栖动物
Entity:Property("GoodsChangeCallBack");                               -- 物品变化回调
Entity:Property("ClickCallBack");                                     -- 物品变化回调

function Entity:ctor()
    self.__goods__ = {};
end

function Entity:Init(opts)
    opts = opts or {};

    if (opts.name) then self:SetName(opts.name) end 
    if (opts.opacity) then self:SetOpacity(opts.opacity) end
    if (opts.assetfile and string.match(opts.assetfile, "^@")) then
        opts.assetfile = string.gsub(opts.assetfile, "@", GetWorldDirectory());
        opts.assetfile = ToCanonicalFilePath(opts.assetfile);
    end

    self:SetBlockPos(opts.bx or 0, opts.by or 0, opts.bz or 0);
    self:SetMainAssetPath(opts.assetfile or "character/CC/02human/actor/actor.x");
    self:CreateInnerObject(self:GetMainAssetPath(), true, 0, 1, self:GetSkin());
	self:RefreshClientModel();
    self:Attach();

    __AddEntity__(self);

    self:SetPhysicsRadius(opts.physicsRadius or 0.5);
    self:SetPhysicsHeight(opts.physicsHeight or 1);
    self:SetSkipPicking(false);
    self:SetBiped(opts.biped);
    self:SetDestroyBeCollided(opts.destroyBeCollided);

    return self;
end

function Entity:SetPosition(x, y, z)
    Entity._super.SetPosition(self, x, y, z);
    self:UpdatePosition();
end

function Entity:SetBlockPos(bx, by, bz)
    Entity._super.SetBlockPos(self, bx, by, bz);
    self:UpdatePosition();
end

function Entity:GetBlockIndex()
    local bx, by, bz = self:GetBlockPos();
    return ConvertToBlockIndex(bx, by, bz);
end

function Entity:UpdatePosition()
    local new_block_index = self:GetBlockIndex();
    local old_block_index = self.__block_index__;
    if (old_block_index and __all_block_index_entity__[old_block_index]) then
        __all_block_index_entity__[old_block_index][self] = nil;
        if (not next(__all_block_index_entity__[old_block_index])) then __all_block_index_entity__[old_block_index] = nil end
    end
    __all_block_index_entity__[new_block_index] = __all_block_index_entity__[new_block_index] or {};
    __all_block_index_entity__[new_block_index][self] = self;

    -- 不精准碰撞
    if (old_block_index == new_block_index) then return end 
    self.__block_index__ = new_block_index;
    self:CheckEntityCollision();
end

function Entity:MoveForward(dist, duration)
    local facing = self:GetFacing();
    local distance = (dist or 1) * __BlockSize__;
    local dx, dy, dz = math.cos(facing) * distance, 0, -math.sin(facing) * distance;
    local x, y, z = self:GetPosition();
    local tickCountPerSecond = __get_loop_tick_count__();
    local stepCount = math.floor((duration or 1) * tickCountPerSecond);
    self:SetAnimId(5);
    while(stepCount > 0) do
        if (self:IsDestory()) then return end 
        
        local stepX, stepY, stepZ = dx / stepCount, dy / stepCount, dz / stepCount;
        x, y, z = x + stepX, y + stepY, z + stepZ;
        self:SetPosition(x, y, z);
        stepCount = stepCount - 1;
        dx, dy, dz = dx - stepX, dy - stepY, dz - stepZ;
        sleep();
    end
    self:SetAnimId(0);
end

function Entity:IsDestory()
    return self.__is_destory__;
end

function Entity:Destroy()
    if (self.__is_destory__) then return end
    self.__is_destory__ = true;

    Entity._super.Destroy(self);

    if (self.__block_index__ and __all_block_index_entity__[self.__block_index__]) then
        __all_block_index_entity__[self.__block_index__][self] = nil;
        if (not next(__all_block_index_entity__[self.__block_index__])) then __all_block_index_entity__[self.__block_index__] = nil end
    end

    __RemoveEntity__(self);
end

function Entity:SetAnimId(animId)
    if (not self:GetInnerObject()) then return end
    self:GetInnerObject():SetField("AnimID", animId or 0);
end

function Entity:Turn(degree)
    self:SetFacingDelta(degree * math.pi / 180);
end

function Entity:TurnTo(degree)
    self:SetFacing(mathlib.ToStandardAngle(degree * math.pi / 180));
end

function Entity:AddGoods(goods)
    self.__goods__[goods] = goods;
    self:OnGoodsChange();
end

function Entity:RemoveGoods(goods)
    self.__goods__[goods] = nil;
    self:OnGoodsChange();
end

function Entity:OnGoodsChange()
    local callback = self:GetGoodsChangeCallBack();
    if (type(callback) == "function") then
        callback();
    end
end

function Entity:HasGoods(goods)
    return self.__goods__[goods] ~= nil;
end

local __temp_goods_list__ = {};
function Entity:GetAllGoods()
    local index = 0;
    for _, goods in pairs(self.__goods__) do
        index = index + 1;
        __temp_goods_list__[index] = goods;
    end
    return index, __temp_goods_list__;
end

local __temp_entity_list__ = {};
function Entity:GetAllEntity()
    local index = 0;
    for _, entity in pairs(__GetAllEntity__()) do
        index = index + 1;
        __temp_entity_list__[index] = entity;
    end 
    return index, __temp_entity_list__;
end


function Entity:CanCollideWith(entity)
    return self:IsBiped();
end

function Entity:CanBeCollidedWith(entity)
    return true;
end

function Entity:CheckEntityCollision()
    if (not self:IsBiped()) then return end 

    local aabb = self:GetCollisionAABB();
    local size, entity_list = self:GetAllEntity();
    for index = 1, size do
        local entity = entity_list[index];
        local entity_aabb = entity:GetCollisionAABB();
        if (aabb and entity_aabb and entity ~= self and aabb:Intersect(entity_aabb)) then
            -- 主动碰撞
            if (self:CanCollideWith(entity)) then
                self:CollideWithEntity(entity);
            end
            -- 被碰撞
            if (entity:CanBeCollidedWith(self)) then
                entity:BeCollidedWithEntity(self);
            end
        end
    end
end

function Entity:BeCollidedWithEntity(entity)
    local size, goods_list = self:GetAllGoods();
    for index = 1, size do
        local goods = goods_list[index];
        -- 转移物品
        if (goods:IsCanTransfer()) then 
            self:RemoveGoods(goods);
            entity:AddGoods(goods);
        end
    end

    if (self:IsDestroyBeCollided()) then
        self:Destroy();
    end
end

function Entity:CollideWithEntity(entity)
end

function Entity:OnClick()
    local callback = self:GetClickCallBack();
    if (type(callback) == "function") then callback() end
end

-- local __temp_entity_list__ = {};
-- function Entity:GetEntitiesByAABBExcept(aabb, excludingEntity)
--     local index = 0;
-- 	local min_x, min_y, min_z = aabb:GetMinValues();
-- 	local max_x, max_y, max_z = aabb:GetMaxValues();
	
-- 	min_x, min_y, min_z = ConvertToBlockPosition(min_x, min_y, min_z);
-- 	max_x, max_y, max_z = ConvertToBlockPosition(max_x, max_y, max_z);

-- 	for x = min_x, max_x do
-- 		for y = min_y, max_y do
-- 			for z = min_z, max_z do
-- 				local block_index = ConvertToBlockIndex(x, y, z);
--                 if (__all_block_index_entity__[block_index]) then
--                     for _, entity in pairs(__all_block_index_entity__[block_index]) do
--                         if (entity ~= excludingEntity) then
--                             index = index + 1;
--                             __temp_entity_list__[index] = entity;
--                         end
--                     end
--                 end
-- 			end
-- 		end
-- 	end
-- 	return index, __temp_entity_list__;
-- end